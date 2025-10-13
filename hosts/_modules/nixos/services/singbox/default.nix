{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.singbox;
in {
  options.modules.services.singbox = {
    enable = lib.mkEnableOption "singbox";
    subscription = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "The Shadowsocks links for the singbox subscription.";
    };
  };

  config = lib.mkIf cfg.enable {
    # singbox conflict with dae/mihomo
    networking.firewall.allowedTCPPorts = [1080 7890 9201 11000];

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    networking.firewall.checkReversePath = "loose";
    networking.proxy = {
      httpProxy = "http://127.0.0.1:1080";
      httpsProxy = "http://127.0.0.1:1080";
      noProxy = ".noirprime.com,.homelab.internal,localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
    };
    systemd.services.podman.serviceConfig.Environment = lib.mkIf config.modules.services.podman.enable [
      "HTTP_PROXY=http://127.0.0.1:1080"
      "HTTPS_PROXY=http://127.0.0.1:1080"
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/singbox 0755 appuser appuser - -"
      "d /var/lib/providers 0755 appuser appuser - -"
      "C+ /var/lib/singbox/ui 0755 appuser appuser - ${pkgs.zashboard}"
      "C+ /var/lib/singbox/geoip 0755 appuser appuser - ${pkgs.geo-custom}/singbox/geoip"
      "C+ /var/lib/singbox/geosite 0755 appuser appuser - ${pkgs.geo-custom}/singbox/geosite"
      "C /var/lib/singbox/config.json 0644 appuser appuser - ${pkgs.geo-custom}/singbox/config.example.json"
      "f /var/lib/singbox/cache.db 0644 appuser appuser - -"
    ];

    # docs:https://github.com/yelnoo/sing-box/blob/main/docs/configuration/provider/index.zh.md

    systemd.services.singbox = {
      description = "Universal proxy platform";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "update-subscription" ''
          cd /var/lib/singbox
          export SUBSCRIPTION=$(grep -v '^#' "${cfg.subscription}" | grep -v '^$' | head -1 | cut -d':' -f2-)
          ${pkgs.envsubst}/bin/envsubst '$SUBSCRIPTION' < "config.json" > "config.json.new"
          mv config.json.new config.json
          chmod 644 config.json
        '';
        ExecStart = "${pkgs.singbox-custom}/bin/sing-box run -D /var/lib/singbox -C /var/lib/singbox";
        RuntimeDirectory = "singbox";
        StateDirectory = "singbox";
        User = "appuser";
        Group = "appuser";
        Restart = "always";
        RestartSec = 5;
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
