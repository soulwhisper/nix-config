{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.moviepilot;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.moviepilot = {
    enable = lib.mkEnableOption "moviepilot";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pilot.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9804 9805];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      redir /api /api/
      handle_path /api/* {
        reverse_proxy localhost:9805
      }
      handle {
        reverse_proxy localhost:9804
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/media 0755 appuser appuser - -"
      "d /var/lib/moviepilot 0755 appuser appuser - -"
      "d /var/lib/moviepilot/config 0755 appuser appuser - -"
      "d /var/lib/moviepilot/core 0755 appuser appuser - -"
    ];

    systemd.services.podman-moviepilot.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."moviepilot" = {
      autoStart = true;
      image = "jxxghp/moviepilot-v2:latest";
      extraOptions = ["--pull=newer"];
      ports = [
        "9804:9804/tcp"
        "9805:9805/tcp"
      ];
      environment = {
        PUID = "1001";
        PGID = "1001";
        TZ = "Asia/Shanghai";
        NGINX_PORT = "9804";
        PORT = "9805";
        UMASK = "022";
        SUPERUSER = "admin";
        AUTH_SITE = "iyuu,haidan";
        PROXY_HOST = "http://127.0.0.1:1080"; # proxy needed
        AUTO_DOWNLOAD_USER = "all";
        MOVIEPILOT_AUTO_UPDATE = "false";
        PLUGIN_STATISTIC_SHARE = "false";
        SUBSCRIBE_STATISTIC_SHARE = "false";
      };
      volumes = [
        "/var/lib/media:/media"
        "/var/lib/moviepilot/config:/config"
        "/var/lib/moviepilot/core:/moviepilot/.cache/ms-playwright"
      ];
    };
  };
}
