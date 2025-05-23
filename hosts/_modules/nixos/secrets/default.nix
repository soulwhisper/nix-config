{
  config,
  pkgs,
  ...
}: {
  config = {
    sops.secrets = {
      "networking/easytier/auth".sopsFile = ./secrets.sops.yaml;
      "networking/proxy/subscription".sopsFile = ./secrets.sops.yaml;
      "users/soulwhisper/password" = {
        neededForUsers = true;
        sopsFile = ./secrets.sops.yaml;
      };
    };
  };
}
