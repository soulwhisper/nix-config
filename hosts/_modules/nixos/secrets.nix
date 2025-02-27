{
  config,
  pkgs,
  ...
}: {
  config = {
    sops.secrets = {
      "networking/dae/subscription".sopsFile = ./secrets.sops.yaml;
      "networking/easytier/auth".sopsFile = ./secrets.sops.yaml;
      "users/soulwhisper/password" = {
        neededForUsers = true;
        sopsFile = ./secrets.sops.yaml;
      };
    };
  };
}
