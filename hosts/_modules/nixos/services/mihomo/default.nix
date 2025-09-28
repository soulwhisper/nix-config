{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.mihomo;
in {
  options.modules.services.mihomo = {
    enable = lib.mkEnableOption "mihomo";
    subscriptionFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "The Shadowsocks links for the mihomo subscription.";
    };
  };

  config = lib.mkIf cfg.enable {
    # : mihomo TUN conflicts with dae

    networking.firewall.allowedTCPPorts = [1080 7890 9201];

    networking.firewall.checkReversePath = "loose";
    networking.proxy = {
      httpProxy = "http://127.0.0.1:1080";
      httpsProxy = "http://127.0.0.1:1080";
      noProxy = ".noirprime.com,.homelab.internal,localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
    };
    # add tproxy support
    networking.extraCommands = ''
      ip rule add fwmark 6666 lookup 100 2>/dev/null || true
      ip route add local 0.0.0.0/0 dev lo table 100 2>/dev/null || true
      ip -6 rule add fwmark 6666 lookup 100 2>/dev/null || true
      ip -6 route add local ::/0 dev lo table 100 2>/dev/null || true
    '';
    networking.nftables.ruleset = ''
      define PROXY_MARK = 6666
      define PROXY_PORT = 7890
      define TUN_DEVICE = "Meta"
      table inet proxy {
        set non_proxy_ips {
          type ipv4_addr; flags interval;
          elements = {
            10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16,
            127.0.0.0/8, 169.254.0.0/16, 224.0.0.0/4,
            255.255.255.255/32
          }
        }

        set non_proxy_ips6 {
          type ipv6_addr; flags interval;
          elements = {
            fc00::/7, fe80::/10, ff00::/8, ::1/128
          }
        }

        set non_proxy_ports {
          type inet_service; flags interval;
          elements = {
            22, 53, 80, 123, 443, 445,
            1080, 1688, 1900, 2049, 3478, 3493,
            5353, 5580, 7070, 7890,
            8080, 8443, 9200, 9201, 9300, 9400,
            10001, 11010, 40000
          }
        }

        set proxy_sockets {
          type mark;
          elements = { $PROXY_MARK };
        }

        chain prerouting {
          type filter hook prerouting priority mangle; policy accept;

          meta iifname $TUN_DEVICE return
          meta mark $PROXY_MARK return

          ip daddr @non_proxy_ips return
          ip6 daddr @non_proxy_ips6 return
          meta l4proto { tcp, udp } th dport @non_proxy_ports return

          ip daddr { 224.0.0.0/4, 255.255.255.255 } return
          ip6 daddr { ff00::/8 } return

          ct state { established, related, untracked } return

          meta l4proto tcp tproxy to :$PROXY_PORT meta mark set $PROXY_MARK accept
          meta l4proto udp tproxy to :$PROXY_PORT meta mark set $PROXY_MARK accept
        }

        chain output {
          type route hook output priority mangle; policy accept;

          meta oifname $TUN_DEVICE return
          meta mark $PROXY_MARK return
          socket mark @proxy_sockets return

          ip daddr @non_proxy_ips return
          ip6 daddr @non_proxy_ips6 return
          meta l4proto { tcp, udp } th dport @non_proxy_ports return

          ip daddr { 224.0.0.0/4, 255.255.255.255 } return
          ip6 daddr { ff00::/8 } return

          ct state { established, related, untracked } return
          meta l4proto tcp meta mark set $PROXY_MARK
          meta l4proto udp meta mark set $PROXY_MARK
        }

        chain forward {
          type filter hook forward priority mangle; policy accept;
          meta mark $PROXY_MARK meta l4proto tcp tproxy to :$PROXY_PORT
          meta mark $PROXY_MARK meta l4proto udp tproxy to :$PROXY_PORT
        }
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/mihomo 0755 appuser appuser - -"
      "C /var/lib/mihomo/config.yaml 0644 appuser appuser - ${./config.yaml}"
    ];

    systemd.services.podman.serviceConfig.Environment = lib.mkIf config.modules.services.podman.enable [
      "HTTP_PROXY=http://127.0.0.1:1080"
      "HTTPS_PROXY=http://127.0.0.1:1080"
    ];

    systemd.services.mihomo = {
      description = "Mihomo daemon, A rule-based proxy in Go.";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.unstable.mihomo}/bin/mihomo -d /var/lib/mihomo -f /var/lib/mihomo/config.yaml -ext-ui ${pkgs.metacubexd}";
        RuntimeDirectory = "mihomo";
        StateDirectory = "mihomo";
        Restart = "always";
        RestartSec = 5;
        # env injection not supported, this file serve as a reminder
        EnvironmentFile = [
          "${cfg.subscriptionFile}"
        ];
        # tun configs
        AmbientCapabilities = ["CAP_NET_ADMIN"];
        CapabilityBoundingSet = ["CAP_NET_ADMIN"];
        PrivateDevices = false;
        PrivateUsers = false;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_NETLINK";
      };
    };
  };
}
