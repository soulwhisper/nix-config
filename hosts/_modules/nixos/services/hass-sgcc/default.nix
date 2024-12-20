{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.hass-sgcc;
in
{
  options.modules.services.hass-sgcc = {
    enable = lib.mkEnableOption "hass-sgcc";
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/home-assistant/sgcc";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # environment
  # sops."hass.sgcc.auth": PHONE_NUMBER,PASSWORD,PUSHPLUS_TOKEN
  # "/etc/home-assistant/sgcc.env": HASS_URL,HASS_TOKEN,RECHARGE_NOTIFY

  config = lib.mkIf cfg.enable {
    environment.etc = {
        "home-assistant/sgcc.env".source = pkgs.writeTextFile {
        name = "sgcc.env";
        text = builtins.readFile ./.env;
        };
        "home-assistant/sgcc.env".mode = "0644";
    };

    systemd.tmpfiles.rules = [ "d ${cfg.dataDir}/sqlite.db 0644 root root - -" ];

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-sgcc" = {
      autoStart = true;
      image = "arcw/sgcc_electricity:latest";
      cmd = [ "python3 main.py" ];
      environment = {
        SET_CONTAINER_TIMEZONE="true";
        CONTAINER_TIMEZONE="Asia/Shanghai";
        JOB_START_TIME="05:00";
        DRIVER_IMPLICITY_WAIT_TIME="60";
        RETRY_TIMES_LIMIT="5";
        LOGIN_EXPECTED_TIME="60";
        RETRY_WAIT_TIME_OFFSET_UNIT="10";
        DATA_RETENTION_DAYS="7";
        ENABLE_DATABASE_STORAGE="true";
        DB_NAME="sqlite.db";
        BALANCE="100.0";
      };
      volumes = [
        "${cfg.dataDir}/sqlite.db:/app/sqlite.db"
      ];
      environmentFiles = [
        "/etc/home-assistant/sgcc.env"
      ];
    };
  };
}
