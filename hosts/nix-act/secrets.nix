{
  config,
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
        "networking/dsh/auth" = {
          owner = config.users.users.caddy.name;
          restartUnits = [ "caddy.service" ];
        };
      };
    };
  };
}
