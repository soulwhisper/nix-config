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
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/woodpecker";
    };
    forgejoURL = lib.mkOption {
      type = lib.types.str;
      default = "http://git.noirprime.com";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9201];

    services.caddy.virtualHosts."ci.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9201
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
    ];

    environment.systemPackages = [
      pkgs.woodpecker-cli
    ];

    environment.etc."woodpecker/server.env" = {
      mode = "0644";
      text = ''
        WOODPECKER_FORGEJO_CLIENT=
        WOODPECKER_FORGEJO_SECRET=
      '';
    };
    environment.etc."woodpecker/agent.env" = {
      mode = "0644";
      text = ''
        WOODPECKER_AGENT_SECRET=
      '';
    };

    services.woodpecker-server = {
      enable = true;
      environment = {
        WOODPECKER_HOST = "http://ci.noirprime.com";
        WOODPECKER_OPEN = "false";
        WOODPECKER_ADMIN = "admin";
        WOODPECKER_DISABLE_USER_AGENT_REGISTRATION = "true";
        WOODPECKER_SERVER_ADDR = ":9201";
        WOODPECKER_FORGEJO = "true";
        WOODPECKER_FORGEJO_URL = "${cfg.forgejoURL}";
        WOODPECKER_FORGEJO_CLIENT_FILE = "/etc/woodpecker/server.env";
        WOODPECKER_FORGEJO_SECRET_FILE = "/etc/woodpecker/server.env";
      };
      # environmentFile = ["${cfg.authFile}"];
    };
    services.woodpecker-agents.agents."local" = {
      enable = true;
      extraGroups = ["podman"];
      environment = {
        WOODPECKER_SERVER = "localhost:9201";
        WOODPECKER_BACKEND = "docker";
        DOCKER_HOST = "unix:///run/podman/podman.sock";
        WOODPECKER_BACKEND_DOCKER_VOLUMES = "/etc/timezone:/etc/timezone";
        WOODPECKER_AGENT_SECRET_FILE = "/etc/woodpecker/agent.env";
      };
      # environmentFile = ["${cfg.authFile}"];
    };
  };
}
