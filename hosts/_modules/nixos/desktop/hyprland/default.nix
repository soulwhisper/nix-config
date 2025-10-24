{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop;
in {
  # ! not finished yet !

  config = lib.mkIf (cfg.enable && (cfg.manager == "hyprland")) {
    # : niri
    # instead of raw-hyprland, scrollable-tiling
    # ref:https://github.com/ryan4yin/nix-config/tree/main/home/linux/gui/niri
  };
}
