{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.postgresql;
  pg = config.services.postgresql;
in {
  options.modules.services.postgresql = {
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/postgres";
    };
  };

  config = lib.mkIf pg.enable {
    services.postgresql.enableTCPIP = true;

    services.postgresqlBackup = {
      enable = true;
      location = "${cfg.dataDir}";
    };
  };
}
