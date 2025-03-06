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
  };

  # due to caddy issues, user and dataDir remain default
  # certs: /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [80 443];

    services.caddy = {
      enable = true;
      package = pkgs.caddy-custom;
      globalConfig = ''
        email {$CLOUDFLARE_EMAIL}
        acme_dns cloudflare {$CLOUDFLARE_DNS_API_TOKEN}
      '';
    };

    systemd.services.caddy.serviceConfig.ProtectHome = lib.mkForce false; # avoid file_server 403
    systemd.services.caddy.serviceConfig.EnvironmentFile = ["${cfg.cloudflareToken}"];
    systemd.services.caddy.serviceConfig.AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
    systemd.services.caddy.serviceConfig.CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
  };
}
