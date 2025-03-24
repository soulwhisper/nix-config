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

  # linux-on-zfs and zfs-impermanence as base
  # unlike traditional FHS, nixos can boot with only "/boot" and "/nix";
  # static data in "/nix", state data in "/persist";
  # default root zpool => rpool;
  # dataset "/persist/apps", "%s/appname" => "/var/lib/appname";
  # dataset "/persist/cfgs", "%s/appname" => "/etc/appname";

  config = lib.mkIf cfg.enable {
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs = {
        devNodes = "/dev/disk/by-id";
        extraPools = cfg.mountPoolsAtBoot;
        forceImportRoot = true; # not recommended, but stable; todo: disable after tests
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
