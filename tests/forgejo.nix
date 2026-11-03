{ pkgs, ... }:
let
  workflow = pkgs.writeText "forgejo-smoke-workflow.yaml" ''
    run-name: host runner smoke
    on:
      push:
    jobs:
      smoke:
        runs-on: nix
        steps:
          - run: nix --version
  '';
in
{
  name = "forgejo-corp-ci";

  nodes.server =
    { lib, pkgs, ... }:
    {
      imports = [
        ../hosts/_modules/nixos/services/forgejo
        ../hosts/_modules/nixos/services/restic
      ];

      # The production module only needs to know whether Caddy is enabled.
      options.modules.services.caddy.enable = lib.mkEnableOption "test Caddy";

      config = {
        networking.hostName = "forgejo-test";
        virtualisation.memorySize = 4096;
        virtualisation.cores = 2;

        modules.services.caddy.enable = false;
        modules.services.forgejo = {
          enable = true;
          domain = "localhost";
          rootUrl = "http://localhost:9003/";
          runner = {
            enable = true;
            url = "http://localhost:9003/";
          };
        };
        modules.services.restic = {
          enable = true;
          endpointFile = pkgs.writeText "restic-repository" "/var/lib/restic-repo";
          credentialFile = pkgs.writeText "restic-environment" "";
          encryptionFile = pkgs.writeText "restic-password" "test-only-password";
          paths = [ "/var/lib/forgejo" ];
          quiesceUnits = [
            "gitea-runner-main.service"
            "forgejo.service"
          ];
        };

        environment.systemPackages = with pkgs; [
          curl
          git
          git-lfs
          jq
          openssh
        ];
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        system.stateVersion = "26.05";
      };
    };

  testScript = ''
    import json
    import shlex

    start_all()
    server.wait_for_unit("forgejo.service")
    server.wait_for_open_port(9003)
    server.wait_for_open_port(9004)
    server.wait_for_unit("gitea-runner-main.service")
    server.wait_until_succeeds(
        "journalctl -o cat -u gitea-runner-main.service | grep -q 'Runner registered successfully'",
        timeout=30,
    )

    server.succeed("curl --fail --output /tmp/signup.html http://localhost:9003/user/sign_up")
    server.succeed("grep -q 'Registration is disabled' /tmp/signup.html")
    server.succeed(
        "su -l forgejo -c 'GITEA_WORK_DIR=/var/lib/forgejo FORGEJO_WORK_DIR=/var/lib/forgejo "
        + "forgejo admin user create --username test --password test-password "
        + "--email test@localhost --admin --must-change-password=false'"
    )
    server.succeed(
        "curl --fail -u test:test-password -H 'Content-Type: application/json' "
        + "-d '{\"name\":\"repo\",\"private\":true,\"auto_init\":false}' "
        + "http://localhost:9003/api/v1/user/repos"
    )
    server.succeed(
        "curl --fail -X PATCH -u test:test-password -H 'Content-Type: application/json' "
        + "-d '{\"has_actions\":true}' http://localhost:9003/api/v1/repos/test/repo"
    )
    server.fail("curl --fail http://localhost:9003/api/v1/repos/test/repo")

    server.succeed("mkdir -p /root/.ssh && ssh-keygen -q -t ed25519 -N \"\" -f /root/.ssh/id_ed25519")
    public_key = server.succeed("cat /root/.ssh/id_ed25519.pub").strip()
    key_payload = shlex.quote(json.dumps({"title": "test", "key": public_key, "read_only": False}))
    server.succeed(
        "curl --fail -u test:test-password -H 'Content-Type: application/json' "
        + "-d " + key_payload + " http://localhost:9003/api/v1/user/keys"
    )

    server.succeed("mkdir /tmp/repo")
    server.succeed("git -C /tmp/repo init -b main")
    server.succeed("git -C /tmp/repo config user.email test@localhost")
    server.succeed("git -C /tmp/repo config user.name test")
    server.succeed("git -C /tmp/repo lfs install --local")
    server.succeed("mkdir -p /tmp/repo/.forgejo/workflows")
    server.succeed("cp ${workflow} /tmp/repo/.forgejo/workflows/smoke.yaml")
    server.succeed("echo '*.bin filter=lfs diff=lfs merge=lfs -text' > /tmp/repo/.gitattributes")
    server.succeed("printf 'lfs-smoke' > /tmp/repo/payload.bin")
    server.succeed("git -C /tmp/repo add .")
    server.succeed("git -C /tmp/repo commit -m 'Initial import'")
    server.succeed("git -C /tmp/repo remote add origin http://test:test-password@localhost:9003/test/repo.git")
    server.succeed("git -C /tmp/repo push origin main")

    def workflow_succeeded(_) -> bool:
        response = server.succeed(
            "curl --fail -u test:test-password http://localhost:9003/api/v1/repos/test/repo/actions/tasks"
        )
        runs = json.loads(response).get("workflow_runs")
        if not runs:
            return False
        status = runs[0].get("status")
        server.log(f"Workflow status: {status}")
        if status == "failure":
            raise Exception("Workflow failed")
        return status == "success"

    retry(workflow_succeeded, 60)

    ssh_command = (
        "ssh -i /root/.ssh/id_ed25519 -p 9004 "
        "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    )
    ssh_environment = "GIT_SSH_COMMAND=" + shlex.quote(ssh_command)
    server.succeed(ssh_environment + " git clone forgejo@localhost:test/repo.git /tmp/repo-ssh")
    server.succeed("git -C /tmp/repo-ssh lfs install --local")
    server.succeed(ssh_environment + " git -C /tmp/repo-ssh lfs pull")
    payload = server.succeed("cat /tmp/repo-ssh/payload.bin").strip()
    assert payload == "lfs-smoke", f"Unexpected LFS payload: {payload!r}"

    metrics_token = server.succeed("cat /var/lib/forgejo/metrics_token").strip()
    metrics_header = shlex.quote("Authorization: Bearer " + metrics_token)
    server.succeed("curl --fail -H " + metrics_header + " http://localhost:9003/metrics")

    server.succeed("systemctl start restic-backups-remote.service")
    server.succeed("systemctl is-active --quiet forgejo.service")
    server.succeed("systemctl is-active --quiet gitea-runner-main.service")
    snapshots = json.loads(server.succeed("restic-remote snapshots --json"))
    assert len(snapshots) == 1

    server.succeed("restic-remote restore latest --target /tmp/forgejo-restore")
    server.succeed("test -f /tmp/forgejo-restore/var/lib/forgejo/data/forgejo.db")
    server.succeed("find /tmp/forgejo-restore/var/lib/forgejo/data/lfs -type f | grep -q .")
  '';
}
