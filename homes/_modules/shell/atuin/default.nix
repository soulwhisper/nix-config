{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell.atuin;
in {
  options.modules.shell.atuin = {
    enable = lib.mkEnableOption "atuin";
    sync_address = lib.mkOption {
      type = lib.types.str;
      default = "https://api.atuin.sh";
    };
    key_path = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      package = pkgs.unstable.atuin;
      # daemon.enable = true; # ref:https://github.com/atuinsh/atuin/issues/952, until unstable merged
      flags = [
        "--disable-up-arrow"
      ];
      settings = {
        sync_address = cfg.sync_address;
        key_path = cfg.key_path;
        auto_sync = true;
        sync_frequency = "1m";
        search_mode = "fuzzy";
        sync = {
          records = true;
        };
      };
    };
  };
}
