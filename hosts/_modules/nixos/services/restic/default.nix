{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.restic;
in
{
  options.modules.services.restic = {
    enable = lib.mkEnableOption "restic";
    endpointFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
    };
    credentialFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
    };
    encryptionFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
    };
    dataDir = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
  };

  # sync app files to s3/r2, exclude local minio
  # user = root; if other user, add:CAP_DAC_READ_SEARCH

  config = lib.mkIf cfg.enable {
    services.restic.backups.remote = {
      repositoryFile = "${cfg.endpointFile}";
      environmentFile = "${cfg.credentialFile}";
      passwordFile = "${cfg.encryptionFile}";
      paths = [ "${cfg.dataDir}" ];
      extraBackupArgs = [
        "--skip-if-unchanged"
      ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      initialize = true;
      inhibitsSleep = true;
      createWrapper = true;
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 6"
        "--keep-yearly 0"
      ];
    };
  };
}
