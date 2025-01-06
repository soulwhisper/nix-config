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
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/caddy";
    };
    logDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/logs/caddy";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "d ${cfg.logDir} 0755 appuser appuser - -"
    ];

    services.caddy = {
      enable = true;
      package = pkgs.caddy-custom;
      user = "appuser";
      group = "appuser";
      dataDir = "${cfg.dataDir}";
      logDir = "${cfg.logDir}";
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
