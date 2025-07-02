{
  config,
  pkgs,
  ...
}: {
  config = {
    sops.secrets = {
      "networking/easytier/auth" = {
        owner = config.users.users.appuser.name;
        restartUnits = ["easytier.service"];
        sopsFile = ./secrets.sops.yaml;
      };
      "networking/proxy/subscription" = {
        owner = config.users.users.appuser.name;
        restartUnits = ["mihomo.service"];
        sopsFile = ./secrets.sops.yaml;
      };
      "users/soulwhisper/password" = {
        neededForUsers = true;
        sopsFile = ./secrets.sops.yaml;
      };
    };
  };
}
