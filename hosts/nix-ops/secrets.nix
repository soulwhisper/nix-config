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
        # Dotenv: HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH / ..._SECRET,
        # mounted as the hermes backend's systemd EnvironmentFile=.
        "services/hermes/auth" = {
          restartUnits = [ "hermes-backend.service" ];
        };
      };
    };
  };
}
