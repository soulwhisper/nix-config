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
        "storage/versitygw/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["versitygw.service"];
        };
        "networking/cloudflare/auth" = {
          owner = config.users.users.caddy.name;
          restartUnits = ["caddy.service"];
        };
      };
    };
  };
}
