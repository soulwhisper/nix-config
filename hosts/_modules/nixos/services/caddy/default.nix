{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.caddy;
in {
  options.modules.services.caddy = {
    enable = lib.mkEnableOption "caddy";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # certs: /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443 64646];

    systemd.tmpfiles.rules = [
      "d /var/lib/caddy 0755 caddy caddy - -"
    ];

    services.caddy = {
      enable = true;
      package = pkgs.caddy-custom;
      dataDir = "/var/lib/caddy";
      acmeCA = "https://acme-v02.api.letsencrypt.org/directory";
      globalConfig = ''
        email {$CLOUDFLARE_EMAIL}
        acme_dns cloudflare {$CLOUDFLARE_DNS_API_TOKEN}
        storage file_system /var/lib/caddy
      '';
      extraConfig = ''
        (security_headers) {
          header * {
            Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
            X-Content-Type-Options "nosniff"
            X-Frame-Options "SAMEORIGIN"
            X-XSS-Protection "1; mode=block"
            -Server
            Referrer-Policy strict-origin-when-cross-origin
          }
        }
      '';
      virtualHosts."http://:64646".extraConfig = ''
        handle {
          respond /health "ok:f7k2-xQ9m-Tz3p" 200
        }
      '';
    };

    systemd.services.caddy.serviceConfig.ProtectHome = lib.mkForce false; # avoid file_server 403
    systemd.services.caddy.serviceConfig.EnvironmentFile = ["${cfg.authFile}"];
    systemd.services.caddy.serviceConfig.AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
    systemd.services.caddy.serviceConfig.CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
  };
}
