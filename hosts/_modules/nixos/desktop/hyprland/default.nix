{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop;
in {
  # : Custom Windows Manager, prefer niri with Hyprland Support
  # : ref:https://github.com/ryan4yin/nix-config/tree/main/home/linux/gui

  # ! not finished yet !

  config = lib.mkIf (cfg.manager == "hyperland") {
    environment.systemPackages = with pkgs; [
    ];

    # use greetd instead of uwsm
    # niri, hyprland + sway

    security.pam.services.swaylock = {};
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-hyprland];
    };
  };
}
