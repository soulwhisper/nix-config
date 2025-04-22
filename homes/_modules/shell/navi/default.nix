{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell.navi;
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application Support"
    else config.xdg.configHome;
in {
  options.modules.shell.navi = {
    enable = lib.mkEnableOption "navi";
  };

  config = lib.mkIf cfg.enable {
    programs.navi = {
      enable = true;
      package = pkgs.unstable.navi;
      settings = {
        cheats = {
          paths = [
            "${configDir}/navi/cheats"
          ];
        };
        finder = {
          command = "fzf";
          overrides = "--height=40% --with-nth=2 --no-select-1";
        };
      };
    };

    home.file."${configDir}/navi/cheats/custom.cheat" = {
      source = ./custom.cheat;
    };
  };
}
