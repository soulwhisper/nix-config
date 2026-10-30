{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.services.dsh;
  reverseProxyCaddy = config.modules.services.caddy;
in
{
  options.modules.services.dsh = {
    enable = lib.mkEnableOption "dsh";
    publicAddr = lib.mkOption {
      type = lib.types.str;
      default = "10.10.0.220";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "dsh.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9205];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      basic_auth {
        admin {$DSH_BASIC_AUTH_HASH}
      }
      reverse_proxy localhost:9205 {
        header_up Host {host}
        header_up X-Authentik-Uid {http.auth.user.id}
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/dsh/data 0755 soulwhisper soulwhisper - -"
      "d /var/lib/dsh/workspace soulwhisper soulwhisper - -"
      "d /var/lib/dsh/cache soulwhisper soulwhisper - -"
      "d /var/lib/dsh/logs soulwhisper soulwhisper - -"
      "d /var/lib/dsh/backups soulwhisper soulwhisper - -"
    ];

    systemd.services.podman-dsh-web.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."dsh-web" = {
      autoStart = true;
      image = "ghcr.io/soulwhisper/dsh-web:0.2.2-alpha.2-r1";
      environment = {
        DSH_HOST = "${cfg.publicAddr}";
        DSH_WEB_IP = "${cfg.publicAddr}";
        DSH_PUBLIC_URL= "https://${cfg.domain}";
        DSH_TRUSTED_HOST= [ "${cfg.domain}" ];
        DSH_PORT = "9205";
        DSH_FORWARD_AUTH_HEADER = "x-authentik-uid";
        DSH_FORWARD_AUTH_MAX_CONNECTION_SECONDS = "900";
        DSH_TAVERN_FORWARD_AUTH_ALLOWED_SUBJECTS = [ "admin" ];
        DSH_FORWARD_AUTH_TRUSTED_PROXY_CIDRS = [ "192.168.10.1/32" ];
      };
      volumes = [
        "/var/lib/dsh/data:/data"
        "/var/lib/dsh/workspace:/workspace"
        "/var/lib/dsh/cache:/cache"
        "/var/lib/dsh/logs:/logs"
        "/var/lib/dsh/backups:/backups"
      ];
    };
  };
}
