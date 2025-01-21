{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.home-assistant;
in {
  options.modules.services.home-assistant.sgcc = {
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # environment
  # sops."hass.sgcc.auth": PHONE_NUMBER,PASSWORD,PUSHPLUS_TOKEN
  # "/etc/hass/sgcc.env": HASS_TOKEN

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "hass/sgcc.env".source = pkgs.writeTextFile {
        name = "sgcc.env";
        text = builtins.readFile ./.env;
      };
      "hass/sgcc.env".mode = "0644";
    };

    # SYSTEMD_LOG_LEVEL=debug systemd-tmpfiles --create
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/sgcc 0644 root root - -"
      "f ${cfg.dataDir}/sgcc/sqlite.db 0644 root root - -"
    ];

    # systemctl status podman-hass-sgcc.service
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-sgcc" = {
      autoStart = true;
      image = "arcw/sgcc_electricity:latest";
      cmd = ["python3" "main.py"];
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
        "/etc/hass/sgcc.env"
      ];
    };
  };
}
