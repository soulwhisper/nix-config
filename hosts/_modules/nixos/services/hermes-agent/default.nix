{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.services.hermes-agent;

  hermesPackages = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};

  # Upstream publishes the package only in its own flake (not nixpkgs).
  # Stay on the minimal variant and add Feishu deps explicitly: `full`
  # pulls many optional integrations that are not needed here.
  defaultPackage = hermesPackages.minimal.override {
    extraDependencyGroups = cfg.extraDependencyGroups;
    version = "0.23.1";
    # The tarball input carries no git metadata; keep the release stamp intact.
    rev = "3b421578588243f920886e6fe79a6faa87ea026e";
    lastModified = 1794270273;
  };

  user = "hermes";
  group = "hermes";
  stateDir = "/var/lib/hermes";
  hermesHome = "${stateDir}/.hermes";
  workingDirectory = "${stateDir}/workspace";
  backendPort = 9119;

  # Hermes owns $HERMES_HOME/config.yaml and $HERMES_HOME/.env at runtime.
  # This module never writes either file: it supplies the units, the
  # directories and the package. The dashboard credentials arrive as a
  # systemd EnvironmentFile= from a host secret, so nothing is copied into
  # HERMES_HOME.

  unitEnvironment = {
    HOME = stateDir;
    HERMES_HOME = hermesHome;
    HERMES_MANAGED = "false";
  };

  # rtk backs the rtk-rewrite plugin; git and coreutils cover the terminal tool.
  unitPath = [
    cfg.package
    pkgs.unstable.rtk
    pkgs.bash
    pkgs.coreutils
    pkgs.git
  ];

  serviceConfig = {
    User = user;
    Group = group;
    WorkingDirectory = workingDirectory;
    Restart = "always";
    RestartSec = 5;

    # Shared state: files created by the service stay group-writable so
    # interactive users in the hermes group can read and edit them.
    UMask = "0007";

    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = "read-only";
    PrivateTmp = true;
    ReadWritePaths = [
      stateDir
      workingDirectory
    ];
  };

  gatewayArgv = [
    "${cfg.package}/bin/hermes"
    "gateway"
  ];

  backendArgv = [
    "${cfg.package}/bin/hermes"
    "dashboard"
    "--host"
    cfg.backendHost
    "--port"
    (toString backendPort)
    # CAUTION: a service must not try to open a browser when it starts.
    "--no-open"
  ];
in
{
  options.modules.services.hermes-agent = {
    enable = lib.mkEnableOption "hermes-agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression ''
        inputs.hermes-agent.packages.<system>.minimal.override {
          extraDependencyGroups = [ "feishu" ];
          version = "0.23.1";
        }
      '';
      description = "Hermes Agent package. Defaults to the upstream minimal variant plus the configured extras.";
    };

    extraDependencyGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "feishu" ];
      description = "Optional pyproject dependency groups added to the minimal package.";
    };

    backendHost = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address the dashboard unit binds to. This is deployment state and
        belongs in the host file; the module keeps only the shape. A
        non-loopback address requires dashboard basic auth.
      '';
    };

    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Dotenv file with the dashboard credentials —
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH and
        HERMES_DASHBOARD_BASIC_AUTH_SECRET — handed to the backend as a
        systemd EnvironmentFile=. The host file points this at a sops-nix
        secret path. `str`, not `path`, so nothing is copied into the store.
      '';
      example = lib.literalExpression ''config.sops.secrets."services/hermes/auth".path'';
    };
  };

  config = lib.mkIf cfg.enable {
    # Same plaintext firewall style as the other service modules.
    networking.firewall.allowedTCPPorts = [
      8642
      backendPort
    ];

    users.groups.${group} = { };
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = stateDir;
      createHome = true;
      shell = pkgs.bashInteractive;

      # The cron scheduler launches jobs in a transient `systemd-run --user
      # --scope`, which needs a systemd user manager for this uid. Without
      # linger there is no /run/user/<uid> and dispatch fails closed.
      linger = true;

      extraGroups = [ "systemd-journal" ];
      packages = [ pkgs.unstable.rtk ];
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 2770 ${user} ${group} - -"
      "d ${hermesHome} 2770 ${user} ${group} - -"
      "d ${workingDirectory} 2770 ${user} ${group} - -"
    ]
    ++ map (d: "d ${hermesHome}/${d} 2770 ${user} ${group} - -") [
      "cron"
      "sessions"
      "logs"
      "memories"
      "plugins"
    ];

    # Migration only: earlier revisions wrote .managed, config.yaml and .env
    # from the activation script. Drop the marker so the CLI and the WebUI
    # treat the home as runtime-owned; config.yaml and .env are left alone.
    system.activationScripts."hermes-agent-setup" = lib.stringAfter [ "users" ] ''
      mkdir -p ${hermesHome} ${workingDirectory}
      chown ${user}:${group} ${stateDir} ${hermesHome} ${workingDirectory}
      chmod 2770 ${stateDir} ${hermesHome} ${workingDirectory}
      rm -f ${hermesHome}/.managed
    '';

    systemd.services.hermes-agent = {
      description = "Hermes Agent Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "linger-users.service"
      ];
      wants = [
        "network-online.target"
        "linger-users.service"
      ];

      # The cron scheduler launches jobs in a transient `systemd-run --user
      # --scope`; the gateway resolves the user bus once at startup, so a bus
      # that appears later is a bus this process never sees. Bounded and
      # non-fatal: a gateway without cron beats no gateway.
      preStart = ''
        for _ in $(seq 1 50); do
          [ -S "/run/user/$(id -u)/bus" ] && break
          sleep 0.2
        done
        if [ ! -S "/run/user/$(id -u)/bus" ]; then
          echo "hermes-agent: no user bus at /run/user/$(id -u)/bus after 10s;" \
               "restart-safe cron dispatch will fail for the life of this process" >&2
        fi
      '';

      environment = unitEnvironment;
      path = unitPath;
      serviceConfig = serviceConfig // {
        ExecStart = lib.escapeShellArgs gatewayArgv;
      };
    };

    systemd.services.hermes-backend = {
      description = "Hermes Agent web dashboard and desktop backend";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = unitEnvironment;
      path = unitPath;
      serviceConfig =
        serviceConfig
        // {
          ExecStart = lib.escapeShellArgs backendArgv;
        }
        // lib.optionalAttrs (cfg.authFile != null) {
          EnvironmentFile = [ cfg.authFile ];
        };
    };
  };
}
