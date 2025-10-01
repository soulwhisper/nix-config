{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.tproxy;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [1080 9090 11000];

    systemd.tmpfiles.rules = [
      "d /var/lib/singbox 0755 appuser appuser - -"
      "d /var/lib/providers 0755 appuser appuser - -"
      "C+ /var/lib/singbox/ui 0755 appuser appuser - ${pkgs.zashboard}"
      "C+ /var/lib/singbox/geoip 0755 appuser appuser - ${pkgs.geo-custom}/singbox/geoip"
      "C+ /var/lib/singbox/geosite 0755 appuser appuser - ${pkgs.geo-custom}/singbox/geosite"
      "C /var/lib/singbox/config.json 0644 appuser appuser - ${pkgs.geo-custom}/singbox/config.exmaple.json"
      "f /var/lib/singbox/cache.db 0644 appuser appuser - -"
      "f /var/lib/singbox/providers/sub.txt 0644 appuser appuser - -"
    ];

    systemd.services.singbox = {
      description = "Universal proxy platform";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStart = "${pkgs.singbox-custom}/bin/sing-box -D /var/lib/singbox";
        RuntimeDirectory = "singbox";
        StateDirectory = "singbox";
        User = "appuser";
        Group = "appuser";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
