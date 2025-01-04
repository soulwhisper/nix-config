{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.easytier;
in
{
  options.modules.services.easytier = {
    enable = lib.mkEnableOption "easytier";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    routes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    # peer-status: https://easytier.gd.nkbpal.cn/status/easytier
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "tcp://public.easytier.top:11010"
        "tcp://gz.minebg.top:11010"
        "wss://gz.minebg.top:11012"
        "tcp://156.231.117.80:11010"
        "wss://156.231.117.80:11012"
        "tcp://public.easytier.net:11010"
        "wss://public.easytier.net:11012"
        "tcp://public.server.soe.icu:11010"
        "wss://public.server.soe.icu:11012"
        "tcp://ah.nkbpal.cn:11010"
        "wss://ah.nkbpal.cn:11012"
        "tcp://et.gbc.moe:11011"
        "wss://et.gbc.moe:11012"
        "tcp://et.pub.moe.gift:11111"
        "wss://et.pub.moe.gift:11111"
        "tcp://et.01130328.xyz:11010"
        "tcp://47.103.35.100:11010"
        "tcp://et.ie12vps.xyz:11010"
        "tcp://116.206.178.250:11010"
        "tcp://x.cfgw.rr.nu:11010"
      ];
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-d"
        "--default-protocol" "udp"
        "--latency-first"
        "--relay-all-peer-rpc"
      ];
    };
  };

  # creating tun device by systemd is impossible;

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 11010 11011 11012 ];
    networking.firewall.allowedUDPPorts = [ 11010 11011 ];

    environment.systemPackages = [ pkgs.easytier-custom ];

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."easytier" = {
      autoStart = true;
      image = "easytier/easytier:latest";
      extraOptions = [
        "--privileged"
        "--network=host"
      ];
      cmd = [
        "--network-name" "$NETWORK_NAME"
        "--network-secret" "$NETWORK_SECRET"
        "--relay-network-whitelist" "$NETWORK_NAME"
        (lib.concatMapStringsSep " " (peer: "-p " + peer) cfg.peers)
        (lib.concatMapStringsSep " " (route: "-n " + route) cfg.routes)
        (lib.concatStringsSep " " cfg.extraArgs)
      ];
      environment = {
        TZ="Asia/Shanghai";
      };
      environmentFiles = [
        "${cfg.authFile}"
      ];
    };
  };
}
