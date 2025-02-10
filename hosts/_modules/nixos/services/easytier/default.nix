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
        "--enable-kcp-proxy"
        "--latency-first"
        "--multi-thread"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [11010 11011 11012];
    networking.firewall.allowedUDPPorts = [11010 11011];

    environment.systemPackages = [pkgs.easytier-custom];

    networking.interfaces."easytier0" = {
      virtual = true;
      virtualType = "tun";
      ipv4 = {
        addresses = [
          {
            address = 10.126 .126 .0;
            prefixLength = 24;
          }
        ];
        routes = [
          {
            address = "10.126.126.1";
            prefixLength = 24;
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = fe80:72fb:b0d7:37a9::;
            prefixLength = 64;
          }
        ];
        routes = [
          {
            address = "fe80:72fb:b0d7:37a9::1";
            prefixLength = 64;
          }
        ];
      };
    };

    systemd.services.easytier = {
      description = "Simple, decentralized mesh VPN with WireGuard support";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = lib.concatLists [
          [
            "${pkgs.easytier-custom}/bin/easytier-core"
            "--network-name"
            "$NETWORK_NAME"
            "--network-secret"
            "$NETWORK_SECRET"
          ]
          (lib.concatMap (peer: ["-p" peer]) cfg.peers)
          (lib.concatMap (route: ["-n" route]) cfg.routes)
          cfg.extraArgs
        ];
        Restart = "always";
        AmbientCapabilities = [
          "CAP_NET_ADMIN"
        ];
        User = "appuser";
        Group = "appuser";
        EnvironmentFile = ["${cfg.authFile}"];
      };
    };

    # modules.services.podman.enable = true;
    # virtualisation.oci-containers.containers."easytier" = {
    #   autoStart = true;
    #   image = "easytier/easytier:latest";
    #   extraOptions = [
    #     "--privileged"
    #     "--network=host"
    #   ];
    #   cmd = lib.concatLists [
    #     [
    #       "--network-name"
    #       "$NETWORK_NAME"
    #       "--network-secret"
    #       "$NETWORK_SECRET"
    #     ]
    #     (lib.concatMap (peer: ["-p" peer]) cfg.peers)
    #     (lib.concatMap (route: ["-n" route]) cfg.routes)
    #     cfg.extraArgs
    #   ];
    #   environment = {
    #     TZ = "Asia/Shanghai";
    #   };
    #   environmentFiles = [
    #     "${cfg.authFile}"
    #   ];
    # };
  };
}
