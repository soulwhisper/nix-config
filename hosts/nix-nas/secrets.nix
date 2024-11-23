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
        "storage/minio/root-credentials" = {
          owner = config.users.users.minio.name;
          restartUnits = [ "minio.service" ];
        };
        "networking/cloudflare/auth" = {
          owner = config.users.users.acme.name;
        };
        "networking/dae/subscription" = { };
        "users/soulwhisper/password" = {
          neededForUsers = true;
        };
      };
    };
  };
}
