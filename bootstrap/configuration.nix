{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./zfs-support.nix
  ];
  config = {
    networking.hostName = "nixos";
    system.stateVersion = "25.11";
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };
    users.users.soulwhisper = {
      uid = 1000;
      name = "soulwhisper";
      home = "/home/soulwhisper";
      hashedPassword = "$y$j9T$PEt3REAMQzLLUB40CniJ5/$cYGDysSgf5XVHWpw4DVQT8SBW8TMamLKx84RBmOCd58";
      group = "soulwhisper";
      isNormalUser = true;
      extraGroups = ["wheel"];
    };
    users.groups.soulwhisper = {
      gid = 1000;
    };
    environment.systemPackages = with pkgs; [git];
    boot.supportedFilesystems = {
      xfs = true;
    };
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    fileSystems."/home".neededForBoot = true;
  };
}
