# visit: localhost:8443
# data: /var/lib/unifi/data

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.unifi-controller;
in
{
  options.modules.services.unifi-controller = {
    enable = lib.mkEnableOption "unifi-controller";
  };

  config = lib.mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [ 8443 ];

    services.unifi = {
      enable = true;
      unifiPackage = pkgs.unstable.unifi;
      openFirewall = true;
    };
  };
}
