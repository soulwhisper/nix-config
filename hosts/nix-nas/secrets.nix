{
  pkgs,
  config,
  ...
}:
{
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "backup/restic/endpoint" = {
          restartUnits = [ "restic-backups-remote.service" ];
        };
        "backup/restic/auth" = {
          restartUnits = [ "restic-backups-remote.service" ];
        };
        "backup/restic/encryption" = {
          restartUnits = [ "restic-backups-remote.service" ];
        };
        "backup/zrepl/remote" = {
          restartUnits = [ "zrepl.service" ];
        };
        "storage/minio/root-credentials" = {
          owner = config.users.users.minio.name;
          restartUnits = [ "minio.service" ];
        };
        "networking/cloudflare/auth" = {
          owner = config.users.users.caddy.name;
        };
        "networking/dae/subscription" = { };
        "networking/tailscale/auth" = { };
        "users/soulwhisper/password" = {
          neededForUsers = true;
        };
      };
    };
  };
}
