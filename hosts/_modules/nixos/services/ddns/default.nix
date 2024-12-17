{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.ddns;
in
{
  options.modules.services.ddns = {
    enable = lib.mkEnableOption "ddns";
    CloudflareToken = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.cf-ddns = {
      image = "favonia/cloudflare-ddns:latest";
      extraOptions = [
        "--network=host"
        "--read-only"
        "--cap-drop=all"
        "--security-opt=no-new-privileges"
      ];
      user = "1001:1001";
      environment = {
        CLOUDFLARE_API_TOKEN="{$CLOUDFLARE_DNS_API_TOKEN}";
        DOMAINS="{$CLOUDFLARE_HOMELAB_DOMAIN}";
        PROXIED="false";
      };
      environmentFiles = [ "${cfg.CloudflareToken}" ];
    };
  };
}
