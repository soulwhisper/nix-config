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
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/music 0644 root root - -"
    ];

    services.music-assistant = {
      enable = true;
	    providers = [
	      "filesystem_local"
	      "filesystem_smb"
	      "hass"
	      "hass_players"
      ];
    };
    systemd.services.music-assistant.serviceConfig = lib.mkForce {
      ExecStart = "${lib.getExe pkgs.unstable.music-assistant} --config ${cfg.dataDir}/music --log-level DEBUG";
      StateDirectory = "${cfg.dataDir}/music";
      WorkingDirectory = "${cfg.dataDir}/music";
      Restart = "always";
    };
  };
}
