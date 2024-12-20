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
    dataDir = lib.mkOption {
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
	      "${cfg.dataDir}"
	      "--log-level"
	      "DEBUG"
      ];
    };
    systemd.services.music-assistant.serviceConfig.StateDirectory = "${cfg.dataDir}";
  };
}
