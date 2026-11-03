{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "networking/cloudflare/auth" = {
          owner = config.users.users.caddy.name;
          restartUnits = [ "caddy.service" ];
        };
        "storage/versitygw/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = [ "versitygw.service" ];
        };
        "alerting/pushover/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = [ "gatus.service" ];
        };
      }
      // lib.optionalAttrs config.modules.services.restic.enable {
        "backup/restic/repository" = {
          restartUnits = [ "restic-backups-remote.service" ];
        };
        "backup/restic/auth" = {
          restartUnits = [ "restic-backups-remote.service" ];
        };
        "backup/restic/encryption" = {
          restartUnits = [ "restic-backups-remote.service" ];
        };
      };
    };
  };
}
