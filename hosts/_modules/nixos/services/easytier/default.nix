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
        "--enable-kcp-proxy"  # until pkgs.rustc=1.84, easytier=2.2.0+
        "--latency-first"
        "--multi-thread"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [11010];
    networking.firewall.allowedUDPPorts = [11010 11011];

    environment.systemPackages = [pkgs.easytier-custom];

    # binary package build on nix or not,
    # cant create tun on nix itself, or manage tun on nix with pre-creation
    # systemd.services.easytier = {
    #   description = "Simple, decentralized mesh VPN with WireGuard support";
    #   wantedBy = ["multi-user.target"];
    #   after = ["network.target"];
    #   serviceConfig = {
    #     ExecStart = lib.concatStringsSep " " (builtins.concatLists [
    #       [
    #         "${pkgs.easytier-custom}/bin/easytier-core"
    #         "--network-name $NETWORK_NAME"
    #         "--network-secret $NETWORK_SECRET"
    #       ]
    #       (lib.concatMap (peer: ["-p" peer]) cfg.peers)
    #       (lib.concatMap (route: ["-n" route]) cfg.routes)
    #       cfg.extraArgs
    #     ]);
    #     Restart = "always";
    #     EnvironmentFile = ["${cfg.authFile}"];
    #   };
    # };

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."easytier" = {
      autoStart = true;
      image = "easytier/easytier:latest";
      extraOptions = [
        "--privileged"
        "--network=host"
      ];
      cmd = lib.concatLists [
        [
          "--network-name"
          "$NETWORK_NAME"
          "--network-secret"
          "$NETWORK_SECRET"
        ]
        (lib.concatMap (peer: ["-p" peer]) cfg.peers)
        (lib.concatMap (route: ["-n" route]) cfg.routes)
        cfg.extraArgs
      ];
      environment = {
        TZ = "Asia/Shanghai";
      };
      environmentFiles = [
        "${cfg.authFile}"
      ];
    };
  };
}
