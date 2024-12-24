{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.backup.restic;
in
{
  options.modules.services.backup.restic = {
    enable = lib.mkEnableOption "restic";
    configFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
    };
    dataDir = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
  };

  # sync app files to b2/r2
  # sops has account/key, not finished

  config = lib.mkIf cfg.restic.enable {
    services.restic.backups.remote = {
      repository = "b2:apps";
      paths = [ "${cfg.dataDir}" ];
      rcloneConfigFile = "${cfg.restic.configFile}";
      rcloneConfig = {
        type = "b2";
        hard-delete = "true";
      };
      rcloneOptions = {
        fast-list = "true";
      };
      inhibitsSleep = true;
      initialize = true;
    };
  };
}
