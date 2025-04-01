{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.matterbridge;
  configFile = ./matterbridge.toml;
in {
  options.modules.services.matterbridge = {
    enable = lib.mkEnableOption "matterbridge";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/matterbridge";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 appuser appuser - -"
      "C+ ${cfg.dataDir}/matterbridge.toml 0700 appuser appuser - ${configFile}"
      "f ${cfg.dataDir}/matterbridge.env 0644 appuser appuser - -"
    ];

    services.matterbridge = {
      enable = true;
      user = "appuser";
      group = "appuser";
      configPath = "${cfg.dataDir}/matterbridge.toml";
    };
    systemd.services.matterbridge.serviceConfig.EnvironmentFile = ["${cfg.dataDir}/matterbridge.env"];
  };
}
