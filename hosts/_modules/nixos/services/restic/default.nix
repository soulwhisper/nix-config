{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.services.restic;
  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  options.modules.services.restic = {
    enable = lib.mkEnableOption "Restic backups";
    endpointFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = "File containing a REST or SFTP repository URL.";
    };
    credentialFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = "EnvironmentFile containing backend credentials.";
    };
    encryptionFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = "File containing only the Restic repository encryption password.";
    };
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/var/lib" ];
    };
    quiesceUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "gitea-runner-main.service"
        "forgejo.service"
      ];
      description = "Units stopped before the backup and started afterwards in reverse order.";
    };
    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "daily";
    };
    extraOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "sftp.args=-i /run/secrets/backup_key -o StrictHostKeyChecking=yes"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.endpointFile != null;
        message = "modules.services.restic.endpointFile is required when backups are enabled.";
      }
      {
        assertion = cfg.credentialFile != null;
        message = "modules.services.restic.credentialFile is required when backups are enabled.";
      }
      {
        assertion = cfg.encryptionFile != null;
        message = "modules.services.restic.encryptionFile is required when backups are enabled.";
      }
      {
        assertion = cfg.paths != [ ];
        message = "modules.services.restic.paths must not be empty when backups are enabled.";
      }
    ];

    services.restic.backups.remote = {
      repositoryFile = "${cfg.endpointFile}";
      environmentFile = "${cfg.credentialFile}";
      passwordFile = "${cfg.encryptionFile}";
      inherit (cfg) paths extraOptions;
      extraBackupArgs = [
        "--skip-if-unchanged"
      ];
      backupPrepareCommand = lib.optionalString (cfg.quiesceUnits != [ ]) ''
        set -euo pipefail
        ${systemctl} stop ${lib.escapeShellArgs cfg.quiesceUnits}
      '';
      backupCleanupCommand = lib.optionalString (cfg.quiesceUnits != [ ]) ''
        set -euo pipefail
        ${systemctl} start ${lib.escapeShellArgs (lib.reverseList cfg.quiesceUnits)}
      '';
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = 300;
      };
      initialize = true;
      inhibitsSleep = true;
      createWrapper = true;
      runCheck = true;
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 6"
        "--keep-yearly 0"
      ];
    };
  };
}
