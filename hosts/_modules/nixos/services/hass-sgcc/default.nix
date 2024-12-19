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
      default = "/var/lib/hass-sgcc";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc = {
        "home-assistant/sgcc.env".source = pkgs.writeTextFile {
        name = "sgcc-env";
        text = builtins.readFile ./.env;
        };
        "home-assistant/sgcc.env".mode = "0644";
    };

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-sgcc" = {
      autoStart = true;
      image = "arcw/sgcc_electricity:latest";
      entrypoint = "python3 main.py";
      environment = {
        SET_CONTAINER_TIMEZONE="true";
        CONTAINER_TIMEZONE="Asia/Shanghai";
      };
      volumes = [
        "${cfg.dataDir}:/app"
      ];
      environmentFiles = [
        "/etc/home-assistant/sgcc.env"
      ];
    };
  };
}
