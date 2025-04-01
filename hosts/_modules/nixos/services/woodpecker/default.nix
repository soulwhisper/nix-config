{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.woodpecker;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.woodpecker = {
    enable = lib.mkEnableOption "woodpecker";
    forgejoURL = lib.mkOption {
      type = lib.types.str;
      default = "https://git.noirprime.com";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/woodpecker";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "ci.noirprime.com";
    };
  };

  # update variables in "{cfg.dataDir}/woodpecker.env"
  # WOODPECKER_FORGEJO_CLIENT
  # WOODPECKER_FORGEJO_SECRET
  # WOODPECKER_AGENT_SECRET

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9210];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9210
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "f ${cfg.dataDir}/woodpecker.env 0644 appuser appuser - -"
    ];

    environment.systemPackages = [
      pkgs.woodpecker-cli
    ];

    services.woodpecker-server = {
      enable = true;
      environment = {
        WOODPECKER_HOST = "https://ci.noirprime.com";
        WOODPECKER_OPEN = "false";
        WOODPECKER_ADMIN = "admin";
        WOODPECKER_DISABLE_USER_AGENT_REGISTRATION = "true";
        WOODPECKER_SERVER_ADDR = ":9210";
        WOODPECKER_GRPC_ADDR = ":9211";
        WOODPECKER_FORGEJO = "true";
        WOODPECKER_FORGEJO_URL = "${cfg.forgejoURL}";
      };
      environmentFile = ["${cfg.dataDir}/woodpecker.env"];
    };
    services.woodpecker-agents.agents."local" = {
      enable = true;
      extraGroups = ["podman"];
      environment = {
        WOODPECKER_SERVER = "localhost:9211";
        WOODPECKER_BACKEND = "docker";
        DOCKER_HOST = "unix:///run/podman/podman.sock";
        WOODPECKER_BACKEND_DOCKER_VOLUMES = "/etc/timezone:/etc/timezone";
      };
      environmentFile = ["${cfg.dataDir}/woodpecker.env"];
    };
  };
}
