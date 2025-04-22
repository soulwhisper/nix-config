{
  config,
  lib,
  ...
}: let
  cfg = config.modules.security.ssh;
in {
  options.modules.security.ssh = {
    matchBlocks = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };

  config = {
    programs.ssh = {
      enable = true;
      inherit (cfg) matchBlocks;

      controlMaster = "auto";
      controlPath = "~/.ssh/control/%C";

      includes = [
        "config.d/*"
      ];
    };
  };
}
