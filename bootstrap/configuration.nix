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
    networking.hostName = "nix-nas"; # change this to fit host

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

    system.stateVersion = "25.05";

    # zfs support
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs = {
        devNodes = "/dev/disk/by-uuid";
        extraPools = ["rpool"];
        forceImportRoot = true;
      };
      kernelParams = ["zfs.zfs_arc_max=4294967296"]; # 4GB
      initrd.postDeviceCommands = lib.mkAfter ''
        zfs rollback -r rpool/root@blank
      '';
    };
    networking.hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);
    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
  };
}
