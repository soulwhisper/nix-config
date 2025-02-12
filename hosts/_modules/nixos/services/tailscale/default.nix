{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.tailscale;
  routeString = lib.strings.concatStringsSep "," cfg.routes;
in {
  options.modules.services.tailscale = {
    enable = lib.mkEnableOption "tailscale";
    routes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # need manually restart if not activated at least once

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraSetFlags = [
        "--advertise-routes=${routeString}"
        "--accept-routes"
      ];
      authKeyFile = "${cfg.authFile}";
    };
  };
}
