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
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs = {
        forceImportRoot = false;
        extraPools = cfg.mountPoolsAtBoot;
      };
    };

    networking.hostId = builtins.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
  };
}
