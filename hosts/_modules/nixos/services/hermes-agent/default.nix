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
    version = "0.22.7";
  };
in
{
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  options.modules.services.hermes-agent = {
    enable = lib.mkEnableOption "hermes-agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression ''
        inputs.hermes-agent.packages.<system>.minimal.override {
          extraDependencyGroups = [ "feishu" ];
          version = "0.22.7";
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
      description = "Hermes state directory.";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hermes/workspace";
      description = "Agent working directory, written to config.yaml as terminal.cwd.";
    };

    managed = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set HERMES_MANAGED. False keeps config/env writable for runtime edits.";
    };

    readOnlyHome = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Expose the home directory read-only to the service.";
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

    services.hermes-agent = {
      enable = true;
      package = cfg.package;
      inherit (cfg)
        extraPackages
        stateDir
        workingDirectory
        restart
        restartSec
        ;
      backend = {
        inherit (cfg.backend) mode host port;
      };
    };

    # Keep config.yaml/.env editable at runtime. Nix-managed keys still
    # override on activation, but CLI writes are not blocked.
    systemd.services = lib.mkMerge [
      {
        hermes-agent = {
          environment.HERMES_MANAGED = lib.mkForce (if cfg.managed then "true" else "false");
          serviceConfig.ProtectHome = lib.mkForce (if cfg.readOnlyHome then "read-only" else false);
        };
      }
      (lib.mkIf (cfg.backend.mode != "none") {
        hermes-backend = {
          environment.HERMES_MANAGED = lib.mkForce (if cfg.managed then "true" else "false");
          serviceConfig.ProtectHome = lib.mkForce (if cfg.readOnlyHome then "read-only" else false);
        };
      })
    ];

    users.users.hermes = lib.mkIf config.services.hermes-agent.createUser {
      extraGroups = cfg.extraGroups;
    };
  };
}
