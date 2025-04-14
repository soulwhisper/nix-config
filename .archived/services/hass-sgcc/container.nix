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
      "C ${cfg.dataDir}/sgcc/sgcc.env 0644 appuser appuser - ${configFile}"
      "f ${cfg.dataDir}/sgcc/sqlite.db 0644 appuser appuser - -"
    ];

    # container user has to be root;
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-sgcc" = {
      autoStart = true;
      image = "arcw/sgcc_electricity:latest";
      cmd = ["python3" "main.py"];
      extraOptions = ["--pull=newer"];
      environment = {
        SET_CONTAINER_TIMEZONE = "true";
        CONTAINER_TIMEZONE = "Asia/Shanghai";
      };
      volumes = [
        "${cfg.dataDir}/sgcc/sqlite.db:/app/sqlite.db"
      ];
      environmentFiles = [
        "${cfg.dataDir}/sgcc/sgcc.env"
        "${cfg.sgcc.authFile}"
      ];
    };
  };
}
