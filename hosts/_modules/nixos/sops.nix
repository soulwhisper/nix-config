{
  config,
  pkgs,
  ...
}: let
  ageKeyFile = "${config.users.users.soulwhisper.home}/.config/age/keys.txt";
in {
  config = {
    environment.systemPackages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      age.keyFile = ageKeyFile;
      age.generateKey = true;
    };
  };
}
