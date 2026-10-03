{
  config,
  pkgs,
  ...
}: {
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "networking/cloudflare/auth" = {
          owner = config.users.users.caddy.name;
          restartUnits = ["caddy.service"];
        };
        "storage/versitygw/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["versitygw.service"];
        };
      };
    };
  };
}
