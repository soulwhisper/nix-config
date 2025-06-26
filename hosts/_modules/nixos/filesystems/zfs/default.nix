{
  config,
  lib,
  ...
}: let
  cfg = config.modules.filesystems.zfs;
in {
  options.modules.filesystems.zfs = {
    enable = lib.mkEnableOption "zfs";
    mountPoolsAtBoot = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["rpool"];
    };
  };

  # unlike traditional FHS, nixos can boot with only "/boot" and "/nix";
  # static data in "/nix", state data in "/persist";
  # default root pool => rpool;
  # dataset "/persist/apps" => "/var/lib";
  # dataset "/persist/home" => "/home";

  config = lib.mkIf cfg.enable {
    boot = {
      supportedFilesystems = {
        zfs = true;
      };
      zfs = {
        devNodes = "/dev/disk/by-uuid";
        extraPools = cfg.mountPoolsAtBoot;
        forceImportRoot = true; # not recommended, but stable;
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
