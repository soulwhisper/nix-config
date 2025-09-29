{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.tproxy;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [5300];
    networking.firewall.allowedUDPPorts = [5300];

    systemd.tmpfiles.rules = [
      "d /var/lib/mosdns 0755 appuser appuser - -"
      "d /var/lib/mosdns/gen 0755 appuser appuser - -"
      "C+ /var/lib/mosdns/rule 0755 appuser appuser - ${pkgs.geo-custom}/mosdns/rule"
      "C+ /var/lib/mosdns/unpack 0755 appuser appuser - ${pkgs.geo-custom}/mosdns/unpack"
      "C /var/lib/mosdns/config.yaml 0644 appuser appuser - ${pkgs.geo-custom}/mosdns/config.exmaple.yaml"
      "d /var/lib/mosdns/cache_all.dump 0644 appuser appuser - -"
      "d /var/lib/mosdns/cache_direct.dump 0644 appuser appuser - -"
      "d /var/lib/mosdns/cache_proxy.dump 0644 appuser appuser - -"
      "d /var/lib/mosdns/cache_node.dump 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/notin_list.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/notin_rule.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/realip_list.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/realip_rule.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/fakeip_list.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/fakeip_rule.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/v4only_list.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/v4only_rule.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/v6only_list.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/v6only_rule.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/node_v4only_list.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/node_v4only_rule.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/node_v6only_list.txt 0644 appuser appuser - -"
      "f /var/lib/mosdns/gen/node_v6only_rule.txt 0644 appuser appuser - -"
    ];

    systemd.services.mosdns = {
      description = "Modular, pluggable DNS forwarder";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStart = "${pkgs.mosdns-custom}/bin/mosdns start -d /var/lib/mosdns -c ./config.yaml";
        RuntimeDirectory = "mosdns";
        StateDirectory = "mosdns";
        User = "appuser";
        Group = "appuser";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
