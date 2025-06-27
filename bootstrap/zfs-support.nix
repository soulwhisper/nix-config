{
  config,
  lib,
  ...
}: {
  config = {
    boot = {
      supportedFilesystems = {
        zfs = true;
      };
      zfs = {
        devNodes = "/dev/disk/by-uuid";
        extraPools = ["rpool"];
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
