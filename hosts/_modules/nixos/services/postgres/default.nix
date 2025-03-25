{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.postgresql;
in {
  options.modules.services.postgresql = {
    enable = lib.mkEnableOption "postgresql";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/postgresql";
    };
  };

  # enable this module if apps using system postgresql
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 postgres postgres - -"
      "L /var/lib/postgresql - - - - ${cfg.dataDir}"
    ];

    # backup postgres database
    services.postgresqlBackup = {
      enable = true;
      location = "${cfg.dataDir}/backup";
    };
  };
}