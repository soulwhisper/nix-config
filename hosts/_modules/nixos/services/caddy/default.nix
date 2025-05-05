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
    cloudflareToken = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/caddy";
    };
  };

  # certs: /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 caddy caddy - -"
    ];

    services.caddy = {
      enable = true;
      package = pkgs.caddy-custom;
      dataDir = cfg.dataDir;
      globalConfig = ''
        email {$CLOUDFLARE_EMAIL}
        acme_dns cloudflare {$CLOUDFLARE_DNS_API_TOKEN}
        storage file_system ${cfg.dataDir}
      '';
      extraConfig = ''
        (security_headers) {
          header * {
            # enable HSTS
            # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html#strict-transport-security-hsts
            # The recommended value for the max-age is 2 year (63072000 seconds).
            # But we are using 1 hour (3600 seconds) for testing purposes
            # and ensure that the website is working properly before setting
            # to two years.
            Strict-Transport-Security "max-age=3600; includeSubDomains; preload"

            # disable clients from sniffing the media type
            # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html#x-content-type-options
            X-Content-Type-Options "nosniff"

            # clickjacking protection
            # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html#x-frame-options
            X-Frame-Options "SAMEORIGIN"

            # xss protection
            # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html#x-xss-protection
            X-XSS-Protection "1; mode=block"

            # Remove -Server header, which is an information leak
            # Remove Caddy from Headers
            -Server

            # keep referrer data off of HTTP connections
            # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html#referrer-policy
            Referrer-Policy strict-origin-when-cross-origin
          }
        }
      '';
    };

    systemd.services.caddy.serviceConfig.ProtectHome = lib.mkForce false; # avoid file_server 403
    systemd.services.caddy.serviceConfig.EnvironmentFile = ["${cfg.cloudflareToken}"];
    systemd.services.caddy.serviceConfig.AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
    systemd.services.caddy.serviceConfig.CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
  };
}
