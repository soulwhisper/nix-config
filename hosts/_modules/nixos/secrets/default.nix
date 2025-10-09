{
  config,
  pkgs,
  ...
}: {
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
      secrets = {
        "networking/easytier/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["easytier.service"];
          sopsFile = ./nixos.sops.yaml;
        };
        "networking/proxy/subscription" = {
          owner = config.users.users.appuser.name;
          restartUnits = ["dae.service"];
          sopsFile = ./nixos.sops.yaml;
        };
        "users/soulwhisper/password" = {
          neededForUsers = true;
          sopsFile = ./nixos.sops.yaml;
        };
      };
    };
  };
}
