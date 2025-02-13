{
  pkgs,
  config,
  ...
}: {
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "apps/hass-sgcc/auth" = {
          restartUnits = ["podman-hass-sgcc.service"];
        };
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
          owner = config.users.users.appuser.name;
          restartUnits = ["caddy.service"];
        };
        "networking/dae/subscription" = {};
        "networking/easytier/auth" = {};
        "networking/tailscale/auth" = {};
        "users/soulwhisper/password" = {
          neededForUsers = true;
        };
      };
    };
  };
}
