{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell.atuin;
in {
  options.modules.shell.atuin = {
    sync_address = lib.mkOption {
      type = lib.types.str;
      default = "https://api.atuin.sh";
    };
    key_path = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = {
    programs.atuin = {
      enable = true;
      package = pkgs.unstable.atuin;
      daemon.enable = true; # fix zfs sync
      flags = [
        "--disable-up-arrow"
      ];
      settings = {
        auto_sync = true;
        enter_accept = false;
        key_path = cfg.key_path;
        search_mode = "fuzzy";
        sync_address = cfg.sync_address;
        sync_frequency = "1m";
        sync.records = true;
      };
    };
  };
}
