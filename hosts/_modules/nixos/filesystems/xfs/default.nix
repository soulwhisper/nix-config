{
  config,
  lib,
  ...
}: let
  cfg = config.modules.filesystems.xfs;
in {
  options.modules.filesystems.xfs = {
    enable = lib.mkEnableOption "xfs";
  };

  config = lib.mkIf cfg.enable {
    boot = {
      supportedFilesystems = {
        xfs = true;
      };
    };

    # Enable in-memory compressed devices and swap space provided by the zram kernel module.
    # By enable this, we can store more data in memory instead of fallback to disk-based swap devices directly,
    # and thus improve I/O performance when we have a lot of memory.
    #
    #   https://www.kernel.org/doc/Documentation/blockdev/zram.txt
    # Current, only xfs will use swap; all parameters are defaults.
    zramSwap.enable = true;
  };
}
