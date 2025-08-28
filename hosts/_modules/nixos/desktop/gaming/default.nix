{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.gaming;
in {
  options.modules.desktop.gaming = {
    enable = lib.mkEnableOption "desktop gaming";
  };

  config = lib.mkIf cfg.enable {
    # Gaming support for x86_64
    # check:https://wiki.nixos.org/wiki/Steam
    # check:https://github.com/GloriousEggroll/proton-ge-custom
    environment.systemPackages = with pkgs; [
      prismlauncher # minecraft
      steam-run
      winetricks
      wineWowPackages.stable
    ];

    programs.gamemode.enable = true;
    programs.steam.enable = true;
    programs.steam.extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
}
