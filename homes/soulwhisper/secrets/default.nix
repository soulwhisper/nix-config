{
  pkgs,
  config,
  ...
}: let
  ageKeyFile = "${config.xdg.configHome}/age/keys.txt";
  # atuinKeyFile = "${config.xdg.configHome}/atuin/atuin-key";
in {
  config = {
    home.packages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      age.keyFile = ageKeyFile;
      age.generateKey = true;

      secrets = {
      #  atuin_key = {
      #    path = atuinKeyFile;
      #  };
      };
    };

    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = ageKeyFile;
    };
  };
}
