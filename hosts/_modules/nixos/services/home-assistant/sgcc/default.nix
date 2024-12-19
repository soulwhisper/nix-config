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

    systemd.services.hass_sgcc = {
      description = "HomeAssistant sgcc_electricity data fetcher";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre =
        [
          "/bin/sh -c '[[ -f hass_sgcc.db ]] || touch hass_sgcc.db'"
        ];
        ExecStart = lib.getExe pkgs.hass-sgcc;
        Type = "simple";
        Restart = "on-failure";
        WorkingDirectory = "hass_sgcc";
        StateDirectory = "hass_sgcc";
        EnvironmentFile = "/etc/home-assistant/sgcc.env";
      };
    };
  };
}