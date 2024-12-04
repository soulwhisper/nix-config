{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.music-assistant;
in
{
  options.modules.services.music-assistant = {
    enable = lib.mkEnableOption "music-assistant";
    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/music-assistant";
    };
  };

  config = lib.mkIf cfg.enable {
    services.music-assistant = {
      enable = true;
	package = pkgs.unstable.music-assistant;
	providers = [
	  "filesystem_local"
	  "filesystem_smb"
	  "hass"
	  "hass_players"
       ];
       extraOptions = [
	  "--config"
	  "${cfg.configDir}"
	  "--log-level"
	  "DEBUG"
      ];
    };
  };
}
