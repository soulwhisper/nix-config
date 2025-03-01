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
    systemd.timers.auto-upgrade = {
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
      after = ["network-online.target"];
      wants = ["network-online.target"];
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

        rm -rf nix-config 2>> "$ERROR_LOG"
        if ! git clone -b ${cfg.branch} ${cfg.repoUrl} nix-config; then
          echo "❌ Repository clone failed"
          exit 1
        fi

        systemctl stop nixos-rebuild-switch-to-configuration.service
        cd nix-config && nixos-rebuild switch --flake .#${cfg.hostname} || :
        echo "✅ Update COMPLETED [$(date '+%Y-%m-%d %H:%M:%S')]"
      '';
    };
  };
}
