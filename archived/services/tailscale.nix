{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.vpn.tailscale;
in {
  options.modules.services.vpn.tailscale = {
    enable = lib.mkEnableOption "tailscale";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # need manually restart if not activated at least once

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
