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
      settings = {
        cheats = {
          paths = [
            "${configDir}/navi/cheats"
          ];
        };
      };
    };

    home.file."${configDir}/navi/cheats/custom.cheat" = {
      source = ./custom.cheat;
    };
  };
}
