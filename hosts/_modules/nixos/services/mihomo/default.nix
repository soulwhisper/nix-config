{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.mihomo;
  configFile = ./config.yaml;
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

    networking.firewall.allowedTCPPorts = [1080 9201];

    # fix tun not working
    networking.firewall.checkReversePath = "loose";
    # if tun still broken
    # networking.proxy = {
    #   httpProxy = "http://127.0.0.1:1080";
    #   httpsProxy = "http://127.0.0.1:1080";
    #   noProxy = ".noirprime.com,.homelab.internal,localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
    # };

    systemd.tmpfiles.rules = [
      "d /var/lib/mihomo 0755 appuser appuser - -"
      "C /var/lib/mihomo/config.yaml 0644 appuser appuser - ${configFile}"
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
