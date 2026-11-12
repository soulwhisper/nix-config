{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      # :: age
      age = {
        keyFile = "${config.users.users.soulwhisper.home}/.config/age/keys.txt";
        generateKey = false;
      };

      # :: secrets
      # services enabled by default
      secrets = {
        "networking/easytier/config" = {
          owner = config.users.users.appuser.name;
          restartUnits = [ "easytier.service" ];
          sopsFile = ./nixos.sops.yaml;
        };
        "networking/proxy/subscription" = {
          owner = config.users.users.appuser.name;
          restartUnits = [ "mihomo.service" ];
          sopsFile = ./nixos.sops.yaml;
        };
        "users/soulwhisper/password" = {
          neededForUsers = true;
          sopsFile = ./nixos.sops.yaml;
        };
        # Dashboard basic auth keeps only a scrypt hash generated from
        # temp/admin.pass; the plaintext never enters sops or the store.
        "services/hermes/dashboard_password_hash" =
          lib.mkIf (config.modules.services.hermes-agent.enable or false)
            {
              sopsFile = ./nixos.sops.yaml;
            };
        "services/hermes/dashboard_secret" =
          lib.mkIf (config.modules.services.hermes-agent.enable or false)
            {
              sopsFile = ./nixos.sops.yaml;
            };
      };

      # The basic-auth provider reads these from the unit environment. The
      # template is handed to the service as a systemd EnvironmentFile=; it is
      # never copied into $HERMES_HOME/.env, which Hermes owns at runtime.
      templates."hermes-dashboard-env" = lib.mkIf (config.modules.services.hermes-agent.enable or false) {
        content = ''
          HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH=${
            config.sops.placeholder."services/hermes/dashboard_password_hash"
          }
          HERMES_DASHBOARD_BASIC_AUTH_SECRET=${config.sops.placeholder."services/hermes/dashboard_secret"}
        '';
        restartUnits = [ "hermes-backend.service" ];
      };
    };

    modules.services.hermes-agent.environmentFiles =
      lib.mkIf (config.modules.services.hermes-agent.enable or false)
        [ config.sops.templates."hermes-dashboard-env".path ];
  };
}
