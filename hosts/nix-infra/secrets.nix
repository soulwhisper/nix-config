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
        "networking/proxy/subscription" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["dae.service"];
        };
      };
    };
  };
}
