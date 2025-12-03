{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.emby;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.emby = {
    enable = lib.mkEnableOption "emby";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "movie.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9806];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9806
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/media 0755 appuser appuser - -"
      "d /var/lib/media/tvshows 0755 appuser appuser - -"
      "d /var/lib/media/movies 0755 appuser appuser - -"
      "d /var/lib/embyserver 0755 appuser appuser - -"
    ];

    systemd.services.podman-moviepilot.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."embyserver" = {
      autoStart = true;
      image = "docker.io/emby/embyserver:latest";
      pull = "newer";
      ports = [
        "9806:8096/tcp"
      ];
      environment = {
        UID = "1001";
        GID = "1001";
        GIDLIST = "26,303"; # group:video/render
      };
      volumes = [
        "/var/lib/media:/mnt/media"
        "/var/lib/embyserver:/config"
      ];
      devices = [
        "/dev/dri:/dev/dri"
      ];
    };
  };
}
