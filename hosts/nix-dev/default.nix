{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  # spec: 4C8G, 1TB, ESXi VM;

  config = {
    # This is a must if "/home" is isolated from "/", for sops.
    fileSystems."/home".neededForBoot = true;

    # services.qemuGuest.enable = true;
    virtualisation.vmware.guest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = true;
        caddy.enable = true;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;

        # : Networking
        easytier.networks = [
          "172.19.82.0/24"
        ];
        tailscale.enable = true;

        # : Monitoring
        gatus = {
          enable = true;
          includeDefaultEndpoints = false;
          pushover.authFile = config.sops.secrets."alerting/pushover/auth".path;
          extraEndpoints = [
            {
              name = "Code: Forgejo HTTPS";
              group = "Code platform";
              url = "https://${config.modules.services.forgejo.domain}/api/forgejo/v1/version";
              conditions = [ "[STATUS] == 200" ];
              interval = "1m";
            }
            {
              name = "Code: Forgejo SSH";
              group = "Code platform";
              url = "tcp://${config.modules.services.forgejo.domain}:${toString config.modules.services.forgejo.sshPort}";
              conditions = [ "[CONNECTED] == true" ];
              interval = "1m";
            }
          ];
        };
        scrutiny.enable = false;
        smartd.enable = false;
        nut.enable = false;

        # : Backup
        restic = {
          # Enable only after adding the external REST/SFTP repository and credentials to SOPS.
          enable = false;
          endpointFile = config.sops.secrets."backup/restic/repository".path;
          credentialFile = config.sops.secrets."backup/restic/auth".path;
          encryptionFile = config.sops.secrets."backup/restic/encryption".path;
          paths = [ "/var/lib/forgejo" ];
          quiesceUnits = [
            "gitea-runner-main.service"
            "forgejo.service"
          ];
          onCalendar = "03:00";
        };

        # : Main
        forgejo = {
          enable = true;
          domain = "git.noirprime.com";
          runner.enable = true;
        };
        versitygw.enable = true; # ep=:9000,9001
        versitygw.authFile = config.sops.secrets."storage/versitygw/auth".path;

        # : TEST
        netbox.enable = false; # sub=box

        # : Others
        kms.enable = true;
        nfs4 = {
          enable = false; # all_squash = 2000:2000
          exports.default = {
            path = "/var/lib/shared";
            subnet = "172.19.82.0/24";
          };
        };
      };
    };
  };
}
