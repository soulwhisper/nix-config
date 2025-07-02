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
  };
}
