{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.unifi-controller;
in {
  options.modules.services.unifi-controller = {
    enable = lib.mkEnableOption "unifi-controller";
  };

  config = lib.mkIf cfg.enable {
    # use ip:8443 in case network failing.

    networking.firewall.allowedTCPPorts = [8080 8443];
    networking.firewall.allowedUDPPorts = [3478 10001];

    services.unifi = {
      enable = true;
      mongodbPackage = pkgs.mongodb-ce;
    };
  };
}
