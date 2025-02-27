{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.home-assistant;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.home-assistant.sgcc = {
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9202];

    services.caddy.virtualHosts."mqtt.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9202
      }
    '';

    services.home-assistant.extraComponents = [
      "mqtt"
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/mqtt 0755 1000 1000 - -" # emqx user
    ];

    environment.etc = {
      "hass/sgcc/app.js".source = ./app.js;
      "hass/sgcc/app.js".mode = "0644";

      "hass/sgcc/state-grid.js".source = ./state-grid.js;
      "hass/sgcc/state-grid.js".mode = "0644";
    };

    systemd.services.hass-sgcc = {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      description = "Home-assistant SGCC powered by PM2";
      serviceConfig = {
        ExecStartPre = "npm install mqtt pm2";
        ExecStart = "pm2-runtime app.js";
        Path = [pkgs.nodejs];
        WorkingDirectory = "/etc/hass/sgcc";
        Restart = "always";
        EnvironmentFile = "${cfg.sgcc.authFile}";
      };
    };

    # systemctl status podman-hass-sgcc.service
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-mqtt" = {
      autoStart = true;
      image = "emqx/emqx:5.8.4";
      ports = [
        "1883:1883/tcp"
        "9202:18083/tcp"
      ];
      environment = {
        EMQX_DASHBOARD__DEFAULT_PASSWORD = "sEcr3T!";
      };
      volumes = [
        "${cfg.dataDir}/mqtt:/opt/emqx/data"
      ];
    };
  };
}
