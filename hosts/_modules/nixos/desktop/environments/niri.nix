{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;
in
{
  config = lib.mkIf (cfg.enable && cfg.environment == "niri") {
    # ref:https://github.com/YaLTeR/niri/wiki
    # The upstream module wires: session entry, xdg portals (gnome+gtk),
    # gnome-keyring, and systemd units.
    programs.niri.enable = true;

    # : Login manager
    services.greetd = {
      enable = true;
      useTextGreeter = true;
      settings.default_session.command = ''
        ${lib.getExe pkgs.tuigreet} \
          --time \
          --remember \
          --asterisks \
          --cmd ${lib.getExe' pkgs.niri "niri-session"}
      '';
    };

    # : Session companions the niri module does not provide
    environment.systemPackages = with pkgs; [
      fuzzel # launcher
      mako # notifications
      swaybg # wallpaper
      swayidle # idle management
      swaylock # screen lock
      waybar # status bar
    ];

    # swaylock authenticates via its own PAM stack
    security.pam.services.swaylock = { };

    # fcitx5 talks to Wayland directly under niri
    i18n.inputMethod.fcitx5.waylandFrontend = true;
  };
}
