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
        "apps/fvtt/auth" = {
          owner = config.users.users.soulwhisper.name; # node uid=1000
          restartUnits = ["podman-fvtt.service"];
        };
        "apps/moviepilot/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["podman-moviepilot.service"];
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
