{
  pkgs,
  config,
  ...
}:
{
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "networking/easytier/auth" = { };
        "users/soulwhisper/password" = {
          neededForUsers = true;
        };
      };
    };
  };
}
