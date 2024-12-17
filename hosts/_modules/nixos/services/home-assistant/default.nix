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
  options.modules.services.home-assistant = {
    enable = lib.mkEnableOption "home-assistant";
    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/home-assistant";
    };
    addons = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
    };
  };

  imports = [
    ./sgcc
  ];

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."hass.noirprime.com".extraConfig = ''
      handle {
	      reverse_proxy localhost:8123
      }
    '';

    # networking.firewall.allowedTCPPorts = [ 8123 ];

    services.home-assistant = {
      enable = true;
      inherit (cfg) configDir;
      config = null;
    };
  };
}
