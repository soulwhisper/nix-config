{
  config,
  pkgs,
  ...
}: {
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "networking/proxy/subscription" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["dae.service"];
        };
      };
    };
  };
}
