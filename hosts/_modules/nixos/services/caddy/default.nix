{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.caddy;
in
{
  options.modules.services.caddy = {
    enable = lib.mkEnableOption "caddy";
    CloudflareToken = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.caddy = {
      enable = true;
      package = ( pkgs.callPackage ./caddy-custom.nix {
        plugins = [ "github.com/caddy-dns/cloudflare@89f16b99c18ef49c8bb470a82f895bce01cbaece" ];
        hash = "sha256-XTNt2QfbKmt+Dryce8FRVhLrHdPkxhj0PPjCDijMuEs=";
      });
      globalConfig = ''
        email {$CLOUDFLARE_EMAIL}
        acme_dns cloudflare {$CLOUDFLARE_DNS_API_TOKEN}
      '';
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile = [ "${cfg.CloudflareToken}" ];
    systemd.services.caddy.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    systemd.services.caddy.serviceConfig.CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
  };
}
