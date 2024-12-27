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
  options.modules.services.hass.music = {
    enable = lib.mkEnableOption "hass-music";
  };

  config = lib.mkIf cfg.music.enable {
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
	      "${cfg.dataDir}/music"
	      "--log-level"
	      "DEBUG"
      ];
    };
    systemd.services.music-assistant.serviceConfig.StateDirectory = lib.mkForce "${cfg.dataDir}/music";
  };
}
