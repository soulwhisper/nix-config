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
        "networking/tailscale/auth" = { };
        "networking/easytier/auth" = { };
        "users/soulwhisper/password" = {
          neededForUsers = true;
        };
      };
    };
  };
}
