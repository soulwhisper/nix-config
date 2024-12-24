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
        "backup/restic/config" = {
          owner = config.users.users.restic.name;
          restartUnits = [ "restic.service" ];
        };
        "backup/zrepl/remote" = {
          owner = config.users.users.zrepl.name;
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
        "networking/tailscale/auth" = {
          owner = config.users.users.tailscale.name;
        };
        "users/soulwhisper/password" = {
          neededForUsers = true;
        };
      };
    };
  };
}
