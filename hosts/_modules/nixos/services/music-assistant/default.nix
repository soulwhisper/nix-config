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
	      "/var/lib/music-assistant"
	      "--log-level"
	      "DEBUG"
      ];
    };
  };
}
