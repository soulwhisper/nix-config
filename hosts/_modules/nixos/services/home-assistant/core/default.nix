{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.home-assistant;
in
{
  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."hass.noirprime.com".extraConfig = ''
      handle {
	      reverse_proxy localhost:8123
      }
    '';

    # networking.firewall.allowedTCPPorts = [ 8123 ];

    services.home-assistant = {
      enable = true;
      configDir = "${cfg.dataDir}/core";

      # configs not set yet
      config = null;
    };
  };
}