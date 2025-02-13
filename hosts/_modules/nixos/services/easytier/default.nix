{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.easytier;
in {
  options.modules.services.easytier = {
    enable = lib.mkEnableOption "easytier";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    routes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "tcp://public.easytier.top:11010"
      ];
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-d"
        "--no-tun"
        "--socks5 1081"
        "--enable-kcp-proxy"
        "--latency-first"
        "--multi-thread"
        "--relay-all-peer-rpc"
        "--relay-network-whitelist"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # use userspace networking instead of tun, like tailscale, with socks5:1081;
    # with opnsense nat passthrough, direct connect is faster than public peers.

    networking.firewall.allowedTCPPorts = [11010];
    networking.firewall.allowedUDPPorts = [11010 11011];

    environment.systemPackages = [pkgs.easytier-custom];

    systemd.services.easytier = {
      description = "Simple, decentralized mesh VPN with WireGuard support";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " (builtins.concatLists [
          [
            "${pkgs.easytier-custom}/bin/easytier-core"
            "--network-name $NETWORK_NAME"
            "--network-secret $NETWORK_SECRET"
          ]
          (lib.concatMap (peer: ["-p" peer]) cfg.peers)
          (lib.concatMap (route: ["-n" route]) cfg.routes)
          cfg.extraArgs
        ]);
        Restart = "always";
        EnvironmentFile = ["${cfg.authFile}"];
      };
    };
  };
}
