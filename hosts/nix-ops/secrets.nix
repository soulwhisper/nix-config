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
        "networking/bind/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["bind.service"];
        };
      };
    };
  };
}
