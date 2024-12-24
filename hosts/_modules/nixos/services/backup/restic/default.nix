{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.backup;
in
{
  options.modules.services.backup.restic = {
    enable = lib.mkEnableOption "restic";
    configFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
    };
  };

  # backup remote files to local, daily
  # this template for google drive, with client_id/client_secret in sops

  config = lib.mkIf cfg.restic.enable {
    services.restic.backups.remote = {
      repository = "${cfg.dataDir}/gdrive";
      rcloneConfigFile = "${cfg.restic.configFile}";
      rcloneConfig = {
        type = "drive";
        scope = "drive.readonly";
        skip-dangling-shortcuts = "true";
      };
      rcloneOptions = {
        fast-list = "true";
      };
      inhibitsSleep = true;
      initialize = true;
    };
  };
}
