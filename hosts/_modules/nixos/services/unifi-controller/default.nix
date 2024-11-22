# visit: localhost:8443

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

    networking.firewall.allowedTCPPorts = [ 8080 8443 ];
    networking.firewall.allowedUDPPorts = [ 3478 10001 ];

    services.unifi = {
      enable = true;
      unifiPackage = pkgs.unstable.unifi;
    };
  };
}
