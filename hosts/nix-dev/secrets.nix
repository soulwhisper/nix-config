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
        "users/soulwhisper/password" = {
          neededForUsers = true;
        };
        "networking/dae/subscription" = { };
      };
    };
  };
}
