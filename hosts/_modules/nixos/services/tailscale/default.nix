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

  # run `systemctl restart tailscaled-set.service` after rebuild

  config = lib.mkIf cfg.enable {
    networking.firewall.trustedInterfaces = ["tailscale0"];

    systemd.services.tailscaled-set.after = lib.mkForce ["tailscaled.service" "tailscaled-autoconnect.service"];

    services.tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      interfaceName = "tailscale0";
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
