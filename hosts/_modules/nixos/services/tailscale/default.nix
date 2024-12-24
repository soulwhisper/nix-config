{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.tailscale;
in
{
  options.modules.services.tailscale = {
    enable = lib.mkEnableOption "tailscale";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      interfaceName = "tailscale0";
      extraSetFlags = [
        "--advertise-routes=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
        "--accept-routes"
      ];
      authKeyFile = "${cfg.authFile}";
    };
  };
}
