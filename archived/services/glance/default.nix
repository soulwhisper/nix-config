{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.glance;
  configFile = ./glance.yaml;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.glance = {
    enable = lib.mkEnableOption "glance";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/glance";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9802];

    services.caddy.virtualHosts."lab.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9802
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "C+ ${cfg.dataDir}/glance.yaml 0755 appuser appuser - ${configFile}"
    ];

    systemd.services.glance = {
      description = "Glance feed dashboard server";
      wants = ["network-online.target"];
      after = ["network-online.target"];

      serviceConfig = {
        ExecStart = "${pkgs.unstable.glance}/bin/glance --config ${cfg.dataDir}/glance.yaml";
        StateDirectory = "glance";
        RuntimeDirectory = "glance";
        User = "appuser";
        Group = "appuser";
      };
    };
  };
}
