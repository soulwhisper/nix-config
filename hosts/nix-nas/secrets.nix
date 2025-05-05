{
  config,
  pkgs,
  ...
}: {
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "backup/restic/endpoint" = {
          restartUnits = ["restic-backups-remote.service"];
        };
        "backup/restic/auth" = {
          restartUnits = ["restic-backups-remote.service"];
        };
        "backup/restic/encryption" = {
          restartUnits = ["restic-backups-remote.service"];
        };
        "storage/minio/root-credentials" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["minio.service"];
        };
        "networking/cloudflare/auth" = {
          owner = config.users.users.caddy.name;
          restartUnits = ["caddy.service"];
        };
        "networking/mihomo/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["mihomo.service"];
        };
      };
    };
  };
}
