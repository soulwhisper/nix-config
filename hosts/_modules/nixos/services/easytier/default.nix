{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.easytier;
  toml = pkgs.formats.toml {};
  baseSettings =
    {
      instance_name = "default";
      listeners = [
        "tcp://0.0.0.0:11010"
        "udp://0.0.0.0:11010"
      ];
      rpc_portal = "127.0.0.1:15888";
      flags = {
        enable_kcp_proxy = true;
        latency_first = true;
        private_mode = true;
      } // lib.optionalAttrs (cfg.networks == []) {
        no_tun = true;
      };
    }
    // lib.optionalAttrs (cfg.networks != []) {
      dhcp = true;
      network = map (cidr: {inherit cidr;}) cfg.networks;
    };
  baseConfigFile = toml.generate "easytier-config.toml" baseSettings;
in {
  options.modules.services.easytier = {
    enable = lib.mkEnableOption "easytier";
    configFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a TOML fragment containing
        [peer] (uri, peer_public_key),
        [network_identity] (network_name, network_secret),
        [secure_mode] (enabled, local_private_key).
      '';
    };
    networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["10.0.0.0/24"];
      description = ''
        Subnet CIDRs to announce as a subnet proxy. Empty list switches
        this node to no_tun mode (mesh-only, no local TUN device).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [11010];
    networking.firewall.allowedUDPPorts = [11010];

    environment.systemPackages = [pkgs.unstable.easytier];

    systemd.services.easytier = {
      description = "Simple, decentralized mesh VPN with WireGuard support";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStartPre = pkgs.writeShellScript "easytier-merge" ''
          { cat ${baseConfigFile}; echo; cat ${cfg.configFile}; } \
            > /var/lib/easytier/config.toml
          chmod 600 /var/lib/easytier/config.toml
        '';
        ExecStart = "${pkgs.unstable.easytier}/bin/easytier-core -c /var/lib/easytier/config.toml --multi-thread";
        StateDirectory = "easytier";
        Restart = "always";
        RestartSec = 5;
        # tun configs; tun needs 'CAP_NET_ADMIN', app needs 'CAP_NET_RAW';
        AmbientCapabilities = ["CAP_NET_ADMIN" "CAP_NET_RAW"];
        CapabilityBoundingSet = ["CAP_NET_ADMIN" "CAP_NET_RAW"];
        PrivateDevices = false;
        PrivateUsers = false;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_NETLINK";
      };
    };
  };
}
