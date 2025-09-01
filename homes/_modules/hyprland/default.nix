{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.hyprland;
in {
  options.modules.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  # nixos linux only

  config = lib.mkIf cfg.enable {
    # : wayland related
    home.sessionVariables = {
      "NIXOS_OZONE_WL" = "1"; # for any ozone-based browser & electron apps to run on wayland
      "MOZ_ENABLE_WAYLAND" = "1"; # for firefox to run on wayland
      "MOZ_WEBRENDER" = "1";
      # enable native Wayland support for most Electron apps
      "ELECTRON_OZONE_PLATFORM_HINT" = "auto";
      # misc
      "_JAVA_AWT_WM_NONREPARENTING" = "1";
      "QT_WAYLAND_DISABLE_WINDOWDECORATION" = "1";
      "QT_QPA_PLATFORM" = "wayland";
      "SDL_VIDEODRIVER" = "wayland";
      "GDK_BACKEND" = "wayland";
      "XDG_SESSION_TYPE" = "wayland";
    };

    home.packages = with pkgs; [
      brightnessctl
      hyprpicker # color picker
      hyprshot # screen shot
      networkmanagerapplet # provide GUI app: nm-connection-editor
      swaybg # the wallpaper
      wf-recorder # screen recording
      wl-clipboard # copying and pasting
      # audio
      alsa-utils
      glxinfo
      imv
      libva-utils
      nvitop
      pavucontrol
      playerctl
      pulsemixer
      vdpauinfo
      vulkan-tools
    ];

    # : hyprland config
    # ref:https://github.com/ryan4yin/nix-config/tree/main/home/linux/gui/base/desktop/conf
    xdg.configFile."mako".source = "${./mako}";
    xdg.configFile."waybar".source = "${./waybar}";
    xdg.configFile."wlogout".source = "${./wlogout}";
    xdg.configFile."hypr/hypridle.conf".source = "${./hypridle.conf}";

    # :: hyprland apps
    programs.mpv = {
      enable = true;
      defaultProfiles = ["gpu-hq"];
      scripts = [pkgs.mpvScripts.mpris];
    };
    services.playerctld.enable = true;
    programs.waybar = {
      enable = true;
      systemd.enable = true;
    };
    programs.swaylock.enable = true;
    programs.wlogout.enable = true;
    services.hypridle.enable = true;
    services.mako.enable = true;
    programs.anyrun = {
      enable = true;
      config = {
        plugins = [
          "${pkgs.anyrun}/lib/libapplications.so"
          "${pkgs.anyrun}/lib/libsymbols.so"
          "${pkgs.anyrun}/lib/librandr.so"
          "${pkgs.anyrun}/lib/librink.so"
          "${pkgs.anyrun}/lib/libshell.so"
        ];
        width.fraction = 0.3;
        y.absolute = 15;
        hidePluginInfo = true;
        closeOnClick = true;
        # custom css for anyrun, based on catppuccin-mocha
        extraCss = ''
          @define-color bg-col  rgba(30, 30, 46, 0.7);
          @define-color bg-col-light rgba(150, 220, 235, 0.7);
          @define-color border-col rgba(30, 30, 46, 0.7);
          @define-color selected-col rgba(150, 205, 251, 0.7);
          @define-color fg-col #D9E0EE;
          @define-color fg-col2 #F28FAD;
          * {
            transition: 200ms ease;
            font-family: "Maple Mono NF CN";
            font-size: 1.3rem;
          }
          #window {
            background: transparent;
          }
          #plugin,
          #main {
            border: 3px solid @border-col;
            color: @fg-col;
            background-color: @bg-col;
          }
          /* anyrun's input window - Text */
          #entry {
            color: @fg-col;
            background-color: @bg-col;
          }
          /* anyrun's output matches entries - Base */
          #match {
            color: @fg-col;
            background: @bg-col;
          }
          /* anyrun's selected entry - Red */
          #match:selected {
            color: @fg-col2;
            background: @selected-col;
          }
          #match {
            padding: 3px;
            border-radius: 16px;
          }
          #entry, #plugin:hover {
            border-radius: 16px;
          }
          box#main {
            background: rgba(30, 30, 46, 0.7);
            border: 1px solid @border-col;
            border-radius: 15px;
            padding: 5px;
          }
        '';
      };
    };
  };
}
