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
