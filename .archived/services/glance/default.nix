{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.glance;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.glance = {
    enable = lib.mkEnableOption "glance";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9802];

    services.caddy.virtualHosts."lab.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9802
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/glance 0755 appuser appuser - -"
      "C /var/lib/glance/glance.yaml 0755 appuser appuser - ${./glance.yaml}"
    ];

    systemd.services.glance = {
      description = "Glance feed dashboard server";
      wants = ["network-online.target"];
      after = ["network-online.target"];

      serviceConfig = {
        ExecStart = "${pkgs.unstable.glance}/bin/glance --config /var/lib/glance/glance.yaml";
        StateDirectory = "glance";
        RuntimeDirectory = "glance";
        User = "appuser";
        Group = "appuser";
      };
    };
  };
}
