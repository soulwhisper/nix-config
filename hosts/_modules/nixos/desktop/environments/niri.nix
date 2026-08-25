{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;

  # python runtime for iNiR's Material You theming + feature scripts
  # (their nix package ships python3 without the modules)
  inirPython = pkgs.python3.withPackages (
    ps: with ps; [
      materialyoucolor
      pygobject3
      ytmusicapi # YT Music sidebar
      evdev # super-tap overview daemon
      pillow
    ]
  );
in
{
  config = lib.mkIf (cfg.enable && cfg.environment == "niri") {
    # ref:https://github.com/YaLTeR/niri/wiki
    # The upstream module wires: session entry, xdg portals (gnome+gtk),
    # gnome-keyring, and systemd units.
    programs.niri.enable = true;

    # : iNiR runtime requirements that live outside their package wrapper
    security.polkit.enable = true; # daemon for iNiR's own polkit agent UI
    programs.ydotool.enable = true; # synthetic input (shell IPC actions)
    programs.dconf.enable = true; # gsettings desktop defaults below
    boot.kernelModules = [ "i2c-dev" ]; # ddcutil external-monitor brightness
    users.groups.i2c = { };
    # : iNiR — full Quickshell shell for niri (end-4 rewrite)
    # replaces waybar/fuzzel/mako/swaylock/swaybg companions
    # NOTE: their nixos-module.nix is NOT imported — NixOS module-arg `pkgs`
    # resolves through the config merge, so any `pkgs.*` force inside
    # `imports` recurses; the unit below mirrors nix/nixos-module.nix
    # (compositor = "niri").
    environment.systemPackages = [
      pkgs.inir
      pkgs.swayidle # iNiR ships no idle daemon
    ];

    systemd.user.services.inir = {
      description = "iNiR shell";
      wantedBy = [ "niri.service" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [
        pkgs.inir
        inirPython
        pkgs.niri # `niri msg` client matching the compositor
      ];
      environment = {
        INIR_SYSTEM_RUNTIME_DIR = "${pkgs.inir}/share/quickshell/inir";
        INIR_FALLBACK_SYSTEM_RUNTIME_DIR = "${pkgs.inir}/share/quickshell/inir";
        QS_DISABLE_CRASH_HANDLER = "1";
        QT_SCALE_FACTOR = "1";
        QT_SCALE_FACTOR_ROUNDING_POLICY = "RoundPreferFloor";
      };
      unitConfig = {
        Requisite = "graphical-session.target";
        StartLimitIntervalSec = 30;
        StartLimitBurst = 3;
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.inir} run --session";
        ExecStopPost = "-${lib.getExe pkgs.inir} cleanup-orphans";
        SuccessExitStatus = 143;
        KillMode = "process";
        KillSignal = "SIGTERM";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStopSec = 15;
        LimitCORE = 0;
        IOSchedulingPriority = 2;
      };
    };

    # : Super-tap daemon — Super key tap toggles the overview
    # (scripts/daemon ships inside the package; Arch setup enables it,
    # upstream nix module does not)
    systemd.user.services.inir-super-overview = {
      description = "iNiR super-tap overview daemon";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      environment.PATH = lib.mkForce "${inirPython}/bin:${lib.makeBinPath [ pkgs.inir ]}";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.inir}/share/quickshell/inir/scripts/daemon/inir_super_overview_daemon.py";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

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

    # fcitx5 talks to Wayland directly under niri
    i18n.inputMethod.fcitx5.waylandFrontend = true;

    # : Home-manager side — desktop defaults + iNiR feature deps
    home-manager.users.soulwhisper = {
      home.packages = with pkgs; [
        # : desktop defaults (dconf below)
        adw-gtk3 # GTK3 theme referenced by dconf settings
        papirus-icon-theme

        # : Qt theming (Material You propagation)
        qt6Packages.qt6ct
        qt6Packages.qtstyleplugin-kvantum
        darkly
        kdePackages.plasma-browser-integration
        kdePackages.kde-cli-tools
        kdePackages.kconfig # kwriteconfig6
        kdePackages.syntax-highlighting # AiChat code blocks

        # : media / tools (iNiR feature set)
        pavucontrol
        socat
        yt-dlp
        cava
        easyeffects
        songrec
        translate-shell
        hyprpicker
        mpv
      ];

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "Papirus-dark";
      };
    };
  };
}
