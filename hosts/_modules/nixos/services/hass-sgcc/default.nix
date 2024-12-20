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
    sgcc-env = lib.mkOption {
      default = "";
      type = lib.types.lines;
    };
  };

  config = lib.mkIf cfg.enable {
    sgcc-env = lib.optional (cfg.sgcc-env == "") (builtins.readFile ./.env);

    systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0755 root root - -" ];

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-sgcc" = {
      autoStart = true;
      image = "arcw/sgcc_electricity:latest";
      cmd = [ "python3 main.py" ];
      environment = {
        SET_CONTAINER_TIMEZONE="true";
        CONTAINER_TIMEZONE="Asia/Shanghai";
      };
      volumes = [
        "${cfg.dataDir}/hass_sgcc.db:/app/hass_sgcc.db"
      ];
      environmentFiles = [
        "${cfg.dataDir}/.env"
      ];
    };
    systemd.services.podman-hass-sgcc.service.preStart = ''
      /bin/sh -c '[[ -f ${cfg.dataDir}/hass_sgcc.db ]] || touch ${cfg.dataDir}/hass_sgcc.db'
      /bin/sh -c '[[ -f ${cfg.dataDir}/.env ]] || echo ${cfg.sgcc-env} > ${cfg.dataDir}/.env'
    '';
  };
}
