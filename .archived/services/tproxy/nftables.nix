{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.tproxy;

  # tproxy backend config
  proxyConfig = {
    tcpPort = 7892; # redirect
    udpPort = 7890; # tproxy
    fwmark = 1000;
    ipv4Table = 100;
    ipv6Table = 200;
  };

  # IPv4 local
  localIPv4Networks = [
    "28.0.0.0/8"
    "8.8.8.8/32"
    "8.8.4.4/32"
    "1.0.0.1/32"
    "1.1.1.1/32"
    "9.9.9.9/32"
    "8.41.4.0/24"
    "23.23.189.144/28"
    "23.246.0.0/18"
    "34.195.253.0/25"
    "37.77.184.0/21"
    "38.72.126.0/24"
    "45.57.0.0/17"
    "52.24.178.0/24"
    "52.35.140.0/24"
    "54.204.25.0/28"
    "54.213.167.0/24"
    "64.120.128.0/17"
    "66.197.128.0/17"
    "69.53.224.0/19"
    "103.87.204.0/22"
    "108.175.32.0/20"
    "185.2.220.0/22"
    "185.9.188.0/22"
    "192.173.64.0/18"
    "198.38.96.0/19"
    "198.45.48.0/20"
    "203.75.84.0/24"
    "203.198.13.0/24"
    "203.198.80.0/24"
    "207.45.72.0/22"
    "208.75.76.0/22"
    "210.0.153.0/24"
    "91.108.56.0/22"
    "91.108.4.0/22"
    "91.108.8.0/22"
    "91.108.16.0/22"
    "91.108.12.0/22"
    "149.154.160.0/20"
    "91.105.192.0/23"
    "91.108.20.0/22"
    "185.76.151.0/24"
    "95.161.64.0/20"
  ];

  # IPv6 local
  localIPv6Networks = [
    "2001:b28:f23d::/48"
    "2001:b28:f23f::/48"
    "2001:67c:4e8::/48"
    "2001:b28:f23c::/48"
    "2a0a:f280::/32"
    "2607:fb10::/32"
    "2620:10c:7000::/44"
    "2a00:86c0::/32"
    "2a03:5640::/32"
    "fc00::/18"
  ];

  # output routing
  routerIPv4Networks = [
    "28.0.0.0/8"
    "8.8.8.8/32"
    "8.8.4.4/32"
    "1.0.0.1/32"
    "1.1.1.1/32"
    "9.9.9.9/32"
  ];

  routerIPv6Networks = [
    "fc00::/18"
  ];

  nftablesRuleset = ''
    table inet custom_tproxy {
      set local_ipv4 {
        type ipv4_addr
        flags interval
        elements = { ${lib.concatStringsSep ", " localIPv4Networks} }
      }

      set local_ipv6 {
        type ipv6_addr
        flags interval
        elements = { ${lib.concatStringsSep ", " localIPv6Networks} }
      }

      set router_ipv4 {
        type ipv4_addr
        flags interval
        elements = { ${lib.concatStringsSep ", " routerIPv4Networks} }
      }

      set router_ipv6 {
        type ipv6_addr
        flags interval
        elements = { ${lib.concatStringsSep ", " routerIPv6Networks} }
      }

      chain tproxy_backend {
        meta l4proto udp meta mark set ${toString proxyConfig.fwmark} tproxy to :${toString proxyConfig.udpPort} accept
      }

      chain tproxy_mark {
        meta mark set ${toString proxyConfig.fwmark}
      }

      chain mangle_prerouting {
        type filter hook prerouting priority mangle; policy accept;
        ip daddr @local_ipv4 meta l4proto udp ct direction original goto tproxy_backend
        ip6 daddr @local_ipv6 meta l4proto udp ct direction original goto tproxy_backend
      }

      chain mangle_output {
        type route hook output priority mangle; policy accept;
        ip daddr @router_ipv4 meta l4proto udp ct direction original goto tproxy_mark
        ip6 daddr @router_ipv6 meta l4proto udp ct direction original goto tproxy_mark
      }

      chain nat_prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        ip daddr @local_ipv4 meta l4proto tcp redirect to :${toString proxyConfig.tcpPort}
        ip6 daddr @local_ipv6 meta l4proto tcp redirect to :${toString proxyConfig.tcpPort}
      }

      chain nat_output {
        type nat hook output priority filter; policy accept;
        ip daddr @router_ipv4 meta l4proto tcp redirect to :${toString proxyConfig.tcpPort}
        ip6 daddr @router_ipv6 meta l4proto tcp redirect to :${toString proxyConfig.tcpPort}
      }
    }
  '';

  ipv4Routes = [
    "28.0.0.0/8 dev lan scope link table ${toString proxyConfig.ipv4Table}"
    "8.8.8.8/32 dev lan scope link table ${toString proxyConfig.ipv4Table}"
    "8.8.4.4/32 dev lan scope link table ${toString proxyConfig.ipv4Table}"
    "1.1.1.1/32 dev lan scope link table ${toString proxyConfig.ipv4Table}"
    "1.0.0.1/32 dev lan scope link table ${toString proxyConfig.ipv4Table}"
    "9.9.9.9/32 dev lan scope link table ${toString proxyConfig.ipv4Table}"
  ];

  ipv6Routes = [
    "2001:b28:f23d::/48 dev lan scope link table ${toString proxyConfig.ipv6Table}"
    "2001:b28:f23f::/48 dev lan scope link table ${toString proxyConfig.ipv6Table}"
    "2001:67c:4e8::/48 dev lan scope link table ${toString proxyConfig.ipv6Table}"
  ];
in {
  config = lib.mkIf cfg.enable {
    networking.nftables = {
      enable = true;
      ruleset = nftablesRuleset;
    };

    systemd.services.custom-routing = {
      description = "Custom routing";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.iproute2}/bin/ip route add table ${toString proxyConfig.ipv4Table} default dev lan || true

        ${builtins.concatStringsSep "\n" (map (
            route: "${pkgs.iproute2}/bin/ip route add ${route} || true"
          )
          ipv4Routes)}

        ${builtins.concatStringsSep "\n" (map (
            route: "${pkgs.iproute2}/bin/ip -6 route add ${route} || true"
          )
          ipv6Routes)}

        ${pkgs.iproute2}/bin/ip rule add fwmark ${toString proxyConfig.fwmark} lookup ${toString proxyConfig.ipv4Table}
        ${pkgs.iproute2}/bin/ip -6 rule add fwmark ${toString proxyConfig.fwmark} lookup ${toString proxyConfig.ipv6Table}
      '';
    };
  };
}
