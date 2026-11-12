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

  hermesHome = "${cfg.stateDir}/.hermes";

  # Hermes owns $HERMES_HOME/config.yaml and $HERMES_HOME/.env at runtime.
  # This module never writes either file: it supplies the units, the
  # directories and the package. Secrets arrive as systemd EnvironmentFile=
  # paths, which keeps them out of the store and out of HERMES_HOME.
  envFiles = map toString cfg.environmentFiles;

  unitEnvironment = {
    HOME = cfg.stateDir;
    HERMES_HOME = hermesHome;
    HERMES_MANAGED = "false";
  };

  unitPath = [
    cfg.package
    pkgs.bash
    pkgs.coreutils
    pkgs.git
  ]
  ++ cfg.extraPackages;

  serviceConfig = {
    User = cfg.user;
    Group = cfg.group;
    WorkingDirectory = cfg.workingDirectory;
    Restart = cfg.restart;
    RestartSec = cfg.restartSec;

    # Shared state: files created by the service stay group-writable so
    # interactive users in the hermes group can read and edit them.
    UMask = "0007";

    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = if cfg.readOnlyHome then "read-only" else false;
    PrivateTmp = true;
    ReadWritePaths = [
      cfg.stateDir
      cfg.workingDirectory
    ];
  }
  // lib.optionalAttrs (envFiles != [ ]) { EnvironmentFile = envFiles; };

  backendArgv = [
    "${cfg.package}/bin/hermes"
    cfg.backend.mode
    "--host"
    cfg.backend.host
    "--port"
    (toString cfg.backend.port)
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

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.unstable.rtk ];
      description = "Extra tools on the agent PATH. Defaults to the unstable rtk release.";
    };

    backend = {
      mode = lib.mkOption {
        type = lib.types.enum [
          "none"
          "serve"
          "dashboard"
        ];
        default = "none";
        description = ''
          `serve` runs the headless JSON-RPC/WebSocket backend used by Hermes
          Desktop and remote clients. `dashboard` includes the same backend
          plus the browser admin UI on the same port.
        '';
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Backend bind address. Non-loopback requires dashboard auth.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 9119;
        description = "Backend port.";
      };
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hermes";
      description = "Hermes state directory. Contains .hermes/ subdir (HERMES_HOME).";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hermes/workspace";
      description = "Agent working directory and the units' WorkingDirectory.";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Runtime env files passed to the units as systemd EnvironmentFile=.
        Use runtime paths only (sops-nix, agenix); a Nix path literal would
        copy the secret into the world-readable store.

        This is not $HERMES_HOME/.env. Hermes owns that file, and anything
        `hermes config` or the WebUI writes there survives a rebuild.
      '';
      example = lib.literalExpression ''[ config.sops.templates."hermes-dashboard-env".path ]'';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "hermes";
      description = "System user running the units.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "hermes";
      description = "System group for the state directory and the units.";
    };

    readOnlyHome = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Expose /home to the services read-only.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "systemd-journal" ];
      description = "Extra groups for the hermes user; systemd-journal allows read-only log inspection.";
    };

    restart = lib.mkOption {
      type = lib.types.str;
      default = "always";
      description = "systemd Restart policy for the Hermes units.";
    };

    restartSec = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "systemd RestartSec for the Hermes units.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Same plaintext firewall style as the other service modules.
    networking.firewall.allowedTCPPorts = [
      8642
    ]
    ++ lib.optional (cfg.backend.mode != "none") cfg.backend.port;

    users.groups.${cfg.group} = { };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.stateDir;
      createHome = true;
      shell = pkgs.bashInteractive;

      # The cron scheduler launches jobs in a transient `systemd-run --user
      # --scope`, which needs a systemd user manager for this uid. Without
      # linger there is no /run/user/<uid> and dispatch fails closed.
      linger = true;

      extraGroups = cfg.extraGroups;
      packages = cfg.extraPackages;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 2770 ${cfg.user} ${cfg.group} - -"
      "d ${hermesHome} 2770 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.workingDirectory} 2770 ${cfg.user} ${cfg.group} - -"
    ]
    ++ map (d: "d ${hermesHome}/${d} 2770 ${cfg.user} ${cfg.group} - -") [
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
      mkdir -p ${hermesHome} ${cfg.workingDirectory}
      chown ${cfg.user}:${cfg.group} ${cfg.stateDir} ${hermesHome} ${cfg.workingDirectory}
      chmod 2770 ${cfg.stateDir} ${hermesHome} ${cfg.workingDirectory}
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
        ExecStart = lib.escapeShellArgs [
          "${cfg.package}/bin/hermes"
          "gateway"
        ];
      };
    };

    systemd.services.hermes-backend = lib.mkIf (cfg.backend.mode != "none") {
      description =
        if cfg.backend.mode == "dashboard" then
          "Hermes Agent web dashboard and desktop backend"
        else
          "Hermes Agent backend for Hermes Desktop";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = unitEnvironment;
      path = unitPath;
      serviceConfig = serviceConfig // {
        ExecStart = lib.escapeShellArgs backendArgv;
      };
    };
  };
}
