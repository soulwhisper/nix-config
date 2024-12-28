{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.hass;
in
{
  options.modules.services.hass = {
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/hass";
    };
    core.enable = lib.mkEnableOption "hass-core";
  };

  config = lib.mkIf cfg.core.enable {
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
