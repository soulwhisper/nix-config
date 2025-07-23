{
  config,
  pkgs,
  ...
}: {
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "apps/default/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["freshrss.service"];
        };
        "apps/moviepilot/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["podman-moviepilot.service"];
        };
        "storage/minio/root-credentials" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["minio.service"];
        };
        "networking/cloudflare/auth" = {
          owner = config.users.users.caddy.name;
          restartUnits = ["caddy.service"];
        };
      };
    };
  };
}
