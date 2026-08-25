{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;

  # python runtime for iNiR's Material You theming scripts
  # (their nix package ships python3 without the module)
  inirPython = pkgs.python3.withPackages (
    ps: with ps; [
      materialyoucolor
      pygobject3
    ]
  );
in
{
  config = lib.mkIf (cfg.enable && cfg.environment == "niri") {
    # ref:https://github.com/YaLTeR/niri/wiki
    # The upstream module wires: session entry, xdg portals (gnome+gtk),
    # gnome-keyring, and systemd units.
    programs.niri.enable = true;

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
  };
}
