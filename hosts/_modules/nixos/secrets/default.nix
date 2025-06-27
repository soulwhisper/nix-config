{
  config,
  pkgs,
  ...
}: {
  config = {
    sops.secrets = {
      "networking/easytier/auth" = {
        sopsFile = ./secrets.sops.yaml;
        restartUnits = ["easytier.service"];
      };
      "networking/proxy/subscription" = {
        owner = config.users.users.appuser.name;
        sopsFile = ./secrets.sops.yaml;
        restartUnits = ["mihomo.service"];
      };
      "users/soulwhisper/password" = {
        neededForUsers = true;
        sopsFile = ./secrets.sops.yaml;
      };
    };
  };
}
