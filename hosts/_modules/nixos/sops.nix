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

    fileSystems."/home".neededForBoot = true;

    sops = {
      age.keyFile = ageKeyFile;
      age.generateKey = false;
    };
  };
}
