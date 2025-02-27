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
      default = "/tmp";
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
      default = "stable";
    };
    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/soulwhisper/nix-config.git";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.auto-rebuild = {
      description = "Auto nix-rebuild Service";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "/etc/auto-rebuild/auto-rebuild.sh";
        LogRateLimitIntervalSec = 0;
      };
    };

    systemd.timers.nix-auto-upgrade = {
      description = "Auto nix-rebuild Timer";
      timerConfig = {
        OnCalendar = "cfg.schedule";
        Persistent = true;
        Unit = "auto-rebuild.service";
      };
      wantedBy = ["timers.target"];
    };

    environment.etc."auto-rebuild/auto-rebuild.sh" = {
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        LOCK_FILE="/tmp/auto-rebuild.lock"
        LOG_FILE="/etc/auto-rebuild/auto-rebuild.log"
        ERROR_LOG="/etc/auto-rebuild/auto-rebuild-errors.log"

        exec 200>"$LOCK_FILE"
        if ! flock -n 200; then
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] Update process conflict" >> "$LOG_FILE"
          exit 0
        fi

        echo "===== Update START [$(date '+%Y-%m-%d %H:%M:%S')] =====" >> "$LOG_FILE"

        cd ${cfg.workdir} || {
          echo "❌ Failed to enter working directory" >> "$LOG_FILE"
          exit 1
        }

        rm -rf nix-config 2>> "$ERROR_LOG"
        if ! git clone -b ${cfg.branch} ${cfg.repoUrl} nix-config >> "$LOG_FILE" 2>> "$ERROR_LOG"; then
          echo "❌ Repository clone failed" >> "$LOG_FILE"
          exit 1
        fi

        cd nix-config && nixos-rebuild switch --flake .#${cfg.hostname} >> "$LOG_FILE" 2>> "$ERROR_LOG" || :
        echo "✅ Update COMPLETED [$(date '+%Y-%m-%d %H:%M:%S')]" >> "$LOG_FILE"
      '';
    };
  };
}
