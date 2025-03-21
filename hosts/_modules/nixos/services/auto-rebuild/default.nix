{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.auto-rebuild;
in {
  options.modules.services.auto-rebuild = {
    enable = lib.mkEnableOption "Automatic nix-rebuild service";
    workdir = lib.mkOption {
      type = lib.types.str;
      default = "/root";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "${config.networking.hostName}";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 02:00:00";
    };
    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
    };
    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/soulwhisper/nix-config";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.timers.auto-rebuild = {
      description = "Auto nix-rebuild Timer";
      timerConfig = {
        OnCalendar = "${cfg.schedule}";
        Persistent = true;
        Unit = "auto-rebuild.service";
      };
      wantedBy = ["timers.target"];
    };

    systemd.services.auto-rebuild = {
      description = "Auto nix-rebuild Service";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      path = [pkgs.flock pkgs.git pkgs.nixos-rebuild pkgs.systemd];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        LogRateLimitIntervalSec = 0;
      };
      script = ''
        LOCK_FILE="/tmp/auto-rebuild.lock"

        exec 200>"$LOCK_FILE"
        if ! flock -n 200; then
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] Update process conflict"
          exit 0
        fi

        echo "===== Update START [$(date '+%Y-%m-%d %H:%M:%S')] ====="

        cd ${cfg.workdir} || {
          echo "❌ Failed to enter working directory"
          exit 1
        }

        rm -rf nix-config
        if ! git clone -b ${cfg.branch} ${cfg.repoUrl} nix-config; then
          echo "❌ Repository clone failed"
          exit 1
        fi

        if systemctl is-active --quiet nixos-rebuild-switch-to-configuration.service; then
          systemctl stop nixos-rebuild-switch-to-configuration.service
        fi

        nixos-rebuild build --flake nix-config/.#${cfg.hostname}
        set +e
        nixos-rebuild switch --flake nix-config/.#${cfg.hostname}
        echo "✅ Update COMPLETED [$(date '+%Y-%m-%d %H:%M:%S')]"
      '';
    };
  };
}
