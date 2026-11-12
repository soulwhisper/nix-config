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

  # Upstream keeps its own locked nixpkgs, so its Python is a different build
  # from ours. Plugin packages must be built with that interpreter or
  # requiredPythonModules drops them silently (it compares pythonModule).
  hermesPythonPackages =
    inputs.hermes-agent.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.python314.pkgs;
  hindsight-client = hermesPythonPackages.callPackage ./hindsight-client.nix {
    aiohttp-retry = hermesPythonPackages.callPackage ./aiohttp-retry.nix { };
  };

  # Upstream publishes the package only in its own flake (not nixpkgs).
  # Stay on the minimal variant and add Feishu deps explicitly: `full`
  # pulls many optional integrations that are not needed here.
  defaultPackage = hermesPackages.minimal.override {
    extraDependencyGroups = cfg.extraDependencyGroups;
    extraPythonPackages = [ hindsight-client ];
    version = "0.23.1";
    # The tarball input carries no git metadata; keep the release stamp intact.
    rev = "3b421578588243f920886e6fe79a6faa87ea026e";
    lastModified = 1794270273;
  };

  serviceConfig = {
    User = "hermes";
    Group = "hermes";
    WorkingDirectory = "/var/lib/hermes/workspace";
    Restart = "always";
    RestartSec = 5;
    UMask = "0007";
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = "read-only";
    PrivateTmp = true;
    ReadWritePaths = [ "/var/lib/hermes" ];
  };

  gatewayArgv = [
    "${cfg.package}/bin/hermes"
    "gateway"
  ];

  backendArgv = [
    "${cfg.package}/bin/hermes"
    "dashboard"
    "--host"
    cfg.address
    "--port"
    "9119"
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
    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      8642
      9119
    ];

    users.groups.hermes = { };
    users.users.hermes = {
      isSystemUser = true;
      group = "hermes";
      home = "/var/lib/hermes";
      createHome = true;
      shell = pkgs.bashInteractive;
      linger = true;
      extraGroups = [ "systemd-journal" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/hermes 2770 hermes hermes - -"
      "d /var/lib/hermes/.hermes 2770 hermes hermes - -"
      "d /var/lib/hermes/.hermes/cron 2770 hermes hermes - -"
      "d /var/lib/hermes/.hermes/sessions 2770 hermes hermes - -"
      "d /var/lib/hermes/.hermes/logs 2770 hermes hermes - -"
      "d /var/lib/hermes/.hermes/memories 2770 hermes hermes - -"
      "d /var/lib/hermes/.hermes/plugins 2770 hermes hermes - -"
      "d /var/lib/hermes/workspace 2770 hermes hermes - -"
    ];

    systemd.services.hermes-gateway = {
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
      environment = {
        HOME = "/var/lib/hermes";
        HERMES_HOME = "/var/lib/hermes/.hermes";
        HERMES_MANAGED = "false";
        HERMES_SUPERVISED_CHILD = "1";
      };
      path = [
        cfg.package
        pkgs.bash
        pkgs.coreutils
        pkgs.git
      ];
      serviceConfig = serviceConfig // {
        ExecStart = lib.escapeShellArgs gatewayArgv;
        # 75 = EX_TEMPFAIL (restart), 78 = EX_CONFIG (park), as in upstream's `gateway install`.
        RestartForceExitStatus = [ 75 ];
        SuccessExitStatus = [ 75 ];
        RestartPreventExitStatus = [ 78 ];
      };
    };

    systemd.services.hermes-backend = {
      description = "Hermes Agent web dashboard and desktop backend";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        HOME = "/var/lib/hermes";
        HERMES_HOME = "/var/lib/hermes/.hermes";
        HERMES_MANAGED = "false";
      };
      path = [
        cfg.package
        pkgs.bash
        pkgs.coreutils
        pkgs.git
      ];
      serviceConfig = serviceConfig // {
        ExecStart = lib.escapeShellArgs backendArgv;
        EnvironmentFile = [ cfg.authFile ];
      };
    };
  };
}
