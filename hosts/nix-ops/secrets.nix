{
  config,
  pkgs,
  ...
}:
{
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;

      # services enabled by optional modules
      secrets = {
        "alerting/pushover/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = [ "gatus.service" ];
        };
        "services/hermes/auth" = {
          owner = config.users.users.hermes.name;
          restartUnits = [ "hermes-backend.service" ];
        };
      };
    };
  };
}
