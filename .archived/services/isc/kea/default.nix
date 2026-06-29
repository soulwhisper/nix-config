{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.isc;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ 67 ];

    # config ref: https://github.com/isc-projects/stork/blob/master/docker/config/agent-kea/kea-dhcp4.conf

    systemd.tmpfiles.rules = [
      "d /run/kea 0750 appuser appuser - -"
      "d /var/log/kea 0755 appuser appuser - -"
      "d /var/lib/kea 0755 appuser appuser - -"
      "d /var/lib/kea/config 0755 appuser appuser - -"
      "C+ /var/lib/kea/config/ctrl-agent.json 0600 appuser appuser - ${./config/ctrl-agent.json}"
      "C+ /var/lib/kea/config/dhcp-common.json 0600 appuser appuser - ${./config/dhcp-common.json}"
      "C+ /var/lib/kea/config/dhcp-ddns.json 0600 appuser appuser - ${./config/dhcp-ddns.json}"
      "C+ /var/lib/kea/config/dhcp4-server.json 0600 appuser appuser - ${./config/dhcp4-server.json}"
      "C+ /var/lib/kea/config/dhcp4-subnets.json 0600 appuser appuser - ${./config/dhcp4-subnets.json}"
      "d /var/lib/kea/hooks 0755 appuser appuser - -"
      "C+ /var/lib/kea/hooks/libdhcp_lease_cmds.so 0555 appuser appuser - ${pkgs.kea}/lib/kea/hooks/libdhcp_lease_cmds.so"
      "C+ /var/lib/kea/hooks/libdhcp_stat_cmds.so 0555 appuser appuser - ${pkgs.kea}/lib/kea/hooks/libdhcp_stat_cmds.so"
      "C+ /var/lib/kea/hooks/libdhcp_pgsql.so 0555 appuser appuser - ${pkgs.kea}/lib/kea/hooks/libdhcp_pgsql.so"
      "C+ /var/lib/kea/hooks/libdhcp_legal_log.so 0555 appuser appuser - ${pkgs.kea}/lib/kea/hooks/libdhcp_legal_log.so"
    ];

    systemd.services.kea-ctrl-agent = {
      description = "ISC-Stack Kea Control Agent Service";
      wants = ["network-online.target"];
      after = ["network-online.target" "bind.service"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      environment = {
        KEA_HOOKS_PATH = "/var/lib/kea/hooks";
      };
      preStart = ''
        if [ ! -f /var/lib/kea/isc.secret ]; then
          sed -n 's/.*secret "\(.*\)";.*/\1/p' /var/lib/bind/isc.key > /var/lib/kea/isc.secret
        fi
      '';
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        RuntimeDirectory = "kea";
        RuntimeDirectoryMode = "0750";
        StateDirectory = "kea";
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${pkgs.kea}/bin/kea-ctrl-agent -c /var/lib/kea/config/ctrl-agent.json";
      };
    };
    systemd.services.kea-dhcp-ddns = {
      description = "ISC-Stack Kea DHCP DDNS Service";
      wants = ["network-online.target"];
      after = ["network-online.target" "bind.service"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      environment = {
        KEA_HOOKS_PATH = "/var/lib/kea/hooks";
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
        RuntimeDirectory = "kea";
        RuntimeDirectoryMode = "0750";
        StateDirectory = "kea";
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${pkgs.kea}/bin/kea-dhcp-ddns -c /var/lib/kea/config/dhcp-ddns.json";
      };
    };
    systemd.services.kea-dhcp4-server = {
      description = "ISC-Stack Kea DHCP4 Service";
      wants = ["network-online.target"];
      after = ["network-online.target" "bind.service"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      environment = {
        KEA_HOOKS_PATH = "/var/lib/kea/hooks";
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        RuntimeDirectory = "kea";
        RuntimeDirectoryMode = "0750";
        StateDirectory = "kea";
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${pkgs.kea}/bin/kea-dhcp4 -c /var/lib/kea/config/dhcp4-server.json";
      };
    };
  };
}
