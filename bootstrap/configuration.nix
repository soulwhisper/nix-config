{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];
  config = {
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

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    system.stateVersion = "24.11";

    # zfs support
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs = {
        devNodes = "/dev/disk/by-uuid";
        extraPools = ["rpool"];
        forceImportRoot = true; # disable after init
      };
      kernelParams = ["zfs.zfs_arc_max=4294967296"]; # 4GB
      initrd.postDeviceCommands = lib.mkAfter ''
        zfs rollback -r rpool/root@blank
      '';
    };
    networking.hostId = "6ed332bc";
    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
  };
}
