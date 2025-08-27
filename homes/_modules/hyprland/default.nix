{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.modules.desktop.manager == "hyperland") {
    wayland.windowManager.hyprland.enable = true;

    # ! not finished yet

    # hyprlock
    programs.hyprlock.enable = true;
    programs.hyprlock.settings = {
      general = {
        disable_loading_bar = true;
        grace = 300;
        hide_cursor = false;
        no_fade_in = false;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = "Input password...";
          shadow_passes = 2;
        }
      ];
    };

    # hypridle
    services.hypridle.enable = true;
    services.hypridle.settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        before_sleep_cmd = "loginctl lock-session";
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || hyprlock ";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };

    # hyprpaper
    services.hyprpaper.enable = true;
    services.hyprpaper.settings = {};

    # hyprpolkitagent
    services.hyprpolkitagent.enable = true;
  };
}
