{
  config,
  pkgs,
  ...
}: let
  ageKeyFile = "${config.xdg.configHome}/age/keys.txt";
in {
  config = {
    home.packages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      age.keyFile = ageKeyFile;
      age.generateKey = false;

      secrets.atuin_key.sopsFile = ./secrets.sops.yaml;
    };

    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = ageKeyFile;
    };
  };
}
