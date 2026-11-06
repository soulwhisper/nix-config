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
        # Dashboard basic auth is a separate generated password: the
        # soulwhisper password above is a yescrypt hash for PAM and cannot be
        # used as the plaintext credential the dashboard hashes.
        "services/hermes/dashboard_password" =
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

      # The module merges environmentFiles into $HERMES_HOME/.env at
      # activation; the basic-auth provider reads these at startup.
      templates."hermes-dashboard-env" = lib.mkIf (config.modules.services.hermes-agent.enable or false) {
        content = ''
          HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${config.sops.placeholder."services/hermes/dashboard_password"}
          HERMES_DASHBOARD_BASIC_AUTH_SECRET=${config.sops.placeholder."services/hermes/dashboard_secret"}
        '';
        restartUnits = lib.optional (
          config.modules.services.hermes-agent.backend.mode != "none"
        ) "hermes-backend.service";
      };
    };
  };
}
