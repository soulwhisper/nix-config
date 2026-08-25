{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;

  # end-4/dots-hyprland config set, tracked via nvfetcher (pkgs/ii-dots)
  iiDots = "${pkgs.ii-dots}/.config";

  # Quickshell: follow nixpkgs (v0.3.0 ⊇ ii's supported pin 7511545e,
  # 2026-03-19; upstream commits since are additive — verified 2026-08-25).
  # Fallback if ii QML breaks on a nixpkgs bump: flake-input pin 7511545e.
  # ii QML imports Kirigami (8 files); merge its QML modules into the
  # quickshell prefix so imports resolve.
  quickshell = pkgs.symlinkJoin {
    name = "quickshell-ii-wrapped";
    paths = [
      pkgs.quickshell
      pkgs.kdePackages.kirigami
    ];
  };

  # Python env standing in for ii's uv venv
  iiPython = pkgs.python3.withPackages (
    ps: with ps; [
      kde-material-you-colors
      material-color-utilities
      materialyoucolor
      pygobject3
      pywayland
      psutil
      pillow
      dbus-python
      requests
      loguru
      setproctitle
    ]
  );
in
lib.mkIf (cfg.enable && cfg.environment == "hyprland") {
  # : Compositor — nixpkgs 26.05 ships Hyprland 0.55.x, the version ii main targets
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # Portals: ii's hyprland-portals.conf prefers hyprland;gtk, FileChooser=kde
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    kdePackages.xdg-desktop-portal-kde
  ];

  # : Session — greetd, consistent with the niri environment
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = ''
      ${lib.getExe pkgs.tuigreet} \
        --time \
        --remember \
        --asterisks \
        --cmd Hyprland
    '';
  };

  # : Services the shell expects (ii execs.lua + QML)
  security.polkit.enable = true; # shell ships its own polkit agent UI
  security.pam.services.hyprlock = { }; # ii lock screen fallback
  programs.ydotool.enable = true; # uinput perms + ydotoold
  services.geoclue2 = {
    enable = true;
    enableDemoAgent = true; # geoclue demo agent used by Quickshell config
  };
  services.gnome.gnome-keyring.enable = lib.mkDefault true;
  programs.dconf.enable = true;
  services.upower.enable = lib.mkDefault true;

  home-manager.users.soulwhisper = {
    home.packages = [
      quickshell
      iiPython
    ]
    ++ (with pkgs; [
      # : audio
      cava
      playerctl
      lxqt.pavucontrol-qt
      easyeffects

      # : backlight / display
      brightnessctl
      ddcutil

      # : basic cli used by shell scripts
      bc
      cliphist
      jq
      wget
      xdg-user-dirs

      # : theming / fonts (ii look — heavy impact, theirs per policy)
      adw-gtk3
      kdePackages.breeze
      kdePackages.breeze-icons
      darkly
      bibata-cursors
      matugen
      rubik
      material-symbols
      twemoji-color-font

      # : hyprland ecosystem
      hypridle
      hyprlock
      hyprpicker
      hyprsunset
      wl-clipboard

      # : kde integration (shell shells out to kcmshell6)
      kdePackages.dolphin
      kdePackages.systemsettings
      kdePackages.bluedevil
      kdePackages.plasma-nm
      kdePackages.kconfig # kwriteconfig6

      # : screen capture / ocr / recording
      slurp
      swappy
      tesseract # eng traineddata included
      wf-recorder
      hyprshot

      # : widgets / shell runtime helpers
      fuzzel
      glib
      imagemagick # magick — wallpaper/asset processing in shell
      kdePackages.kdialog
      libqalculate
      songrec
      translate-shell
      wtype
      ydotool

      # : media / misc referenced by ii configs
      mpv
      btop

      # : fallback terminals (ii script chains + swallow_regex;
      #   ghostty stays the default via custom/variables.lua)
      foot
      kitty
    ]);

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "kde";
      XDG_MENU_PREFIX = "plasma-";
    };

    # ii expects a uv venv here; a nix-built python env serves the same
    # imports without activation-time network access.
    xdg.stateFile."quickshell/.venv".source = iiPython;

    xdg.configFile = {
      # : the shell itself
      "quickshell/ii".source = "${iiDots}/quickshell/ii";

      # : compositor config (entry sources hyprland/* then custom/*)
      "hypr/hyprland.lua".source = "${iiDots}/hypr/hyprland.lua";
      "hypr/hyprland".source = "${iiDots}/hypr/hyprland";
      "hypr/custom/env.lua".source = "${iiDots}/hypr/custom/env.lua";
      "hypr/custom/execs.lua".source = "${iiDots}/hypr/custom/execs.lua";
      "hypr/custom/general.lua".source = "${iiDots}/hypr/custom/general.lua";
      "hypr/custom/keybinds.lua".source = "${iiDots}/hypr/custom/keybinds.lua";
      "hypr/custom/rules.lua".source = "${iiDots}/hypr/custom/rules.lua";
      "hypr/custom/scripts".source = "${iiDots}/hypr/custom/scripts";

      # : app-policy overrides (ours first — see docs/spec-desktop-support.md)
      "hypr/custom/variables.lua".text = ''
        -- soulwhisper overrides: apps conflict policy — ours win as default
        terminal = "ghostty"
        taskManager = "ghostty -e btop"
      '';

      # : launcher / theming (matugen pipeline drives the whole look)
      "fuzzel".source = "${iiDots}/fuzzel";
      "matugen".source = "${iiDots}/matugen";
      "kde-material-you-colors".source = "${iiDots}/kde-material-you-colors";
      "Kvantum".source = "${iiDots}/Kvantum";
      "darklyrc".source = "${iiDots}/darklyrc";
      "dolphinrc".source = "${iiDots}/dolphinrc";
      "kdeglobals".source = "${iiDots}/kdeglobals";
      "konsolerc".source = "${iiDots}/konsolerc";

      # : session / media / portals / app flags
      "mpv".source = "${iiDots}/mpv";
      "xdg-desktop-portal/hyprland-portals.conf".source =
        "${iiDots}/xdg-desktop-portal/hyprland-portals.conf";
      "chrome-flags.conf".source = "${iiDots}/chrome-flags.conf";
      "code-flags.conf".source = "${iiDots}/code-flags.conf";
    };

    # : intentionally NOT deployed (conflicts — ours win)
    # fish/, zshrc.d/, starship.toml   -> our HM shell stack
    # foot/, kitty/ configs            -> ghostty is the terminal
    # fontconfig/                      -> HM fontconfig owns ~/.config/fontconfig
    # thorium-flags.conf               -> not our browser
  };
}
