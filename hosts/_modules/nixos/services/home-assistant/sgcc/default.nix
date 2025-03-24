{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.home-assistant;
  configFile = ./sgcc.env;
in {
  options.modules.services.home-assistant.sgcc = {
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # environment
  # sops."hass.sgcc.auth": PHONE_NUMBER,PASSWORD,PUSHPLUS_TOKEN
  # "${cfg.dataDir}/sgcc/sgcc.env": HASS_TOKEN

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/sgcc 0755 appuser appuser - -"
      "C+ ${cfg.dataDir}/sgcc/sgcc.env 0644 appuser appuser - ${configFile}"
      "f ${cfg.dataDir}/sgcc/sqlite.db 0644 appuser appuser - -"
    ];

    # systemctl status podman-hass-sgcc.service
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-sgcc" = {
      autoStart = true;
      image = "arcw/sgcc_electricity:latest";
      cmd = ["python3" "main.py"];
      # user = "1001:1001"; # container not support
      environment = {
        SET_CONTAINER_TIMEZONE = "true";
        CONTAINER_TIMEZONE = "Asia/Shanghai";
        JOB_START_TIME = "05:00";
        DRIVER_IMPLICITY_WAIT_TIME = "60";
        RETRY_TIMES_LIMIT = "5";
        LOGIN_EXPECTED_TIME = "60";
        RETRY_WAIT_TIME_OFFSET_UNIT = "10";
        DATA_RETENTION_DAYS = "7";
        ENABLE_DATABASE_STORAGE = "true";
        DB_NAME = "sqlite.db";
        BALANCE = "100.0";
        HASS_URL = "host.containers.internal:8123/";
        RECHARGE_NOTIFY = "false"; # until tested
      };
      volumes = [
        "${cfg.dataDir}/sgcc/sqlite.db:/app/sqlite.db"
      ];
      environmentFiles = [
        "${cfg.sgcc.authFile}"
        "${cfg.dataDir}/sgcc/sgcc.env"
      ];
    };
  };
}
