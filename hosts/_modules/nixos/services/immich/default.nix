{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.immich;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.immich = {
    enable = lib.mkEnableOption "immich";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "photo.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9803];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9803
      }
    '';

    services.immich = {
      enable = true;
      package = pkgs.unstable.immich;
      host = "0.0.0.0";
      port = 9803;
      user = "appuser";
      group = "appuser";
      mediaLocation = "/var/lib/immich";
      accelerationDevices = null;
    };
  };
}
