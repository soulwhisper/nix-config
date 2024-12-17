{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.home-assistant;
in
{
  config = lib.mkIf (lib.elem "sgcc" cfg.addons) {
    environment.etc = {
        "home-assistant/sgcc.env".source = pkgs.writeTextFile {
        name = "sgcc-env";
        text = builtins.readFile ./.env;
        };
        "home-assistant/sgcc.env".mode = "0644";
    };

    virtualisation.oci-containers.containers.hass-sgcc = {
      image = "arcw/sgcc_electricity:latest";
      entrypoint = "python3 main.py";
      environment = {
        SET_CONTAINER_TIMEZONE="true";
        CONTAINER_TIMEZONE="Asia/Shanghai";
        ENABLE_DATABASE_STORAGE="true";
        DB_NAME="hass_sgcc.db";
        JOB_START_TIME="05:00";
        DRIVER_IMPLICITY_WAIT_TIME="60";
        RETRY_TIMES_LIMIT="5";
        LOGIN_EXPECTED_TIME="60";
        RETRY_WAIT_TIME_OFFSET_UNIT="10";
        LOG_LEVEL="INFO";
        DATA_RETENTION_DAYS="7";
      };
      volumes = [
        "${cfg.configDir}/sgcc:/app"
      ];
      environmentFiles = [
        "/etc/home-assistant/sgcc.env"
      ];
    };
  };
}
