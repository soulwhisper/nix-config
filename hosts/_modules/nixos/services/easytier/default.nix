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
        "--default-protocol" "udp"
        "--relay-all-peer-rpc"
      ];
    };
  };

  # creating tun device by systemd is impossible;

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 11010 11011 11012 ];
    networking.firewall.allowedUDPPorts = [ 11010 11011 ];

    environment.systemPackages = [ pkgs.unstable.easytier ];  # this only for easytier-cli

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
          "--network-name" "$NETWORK_NAME"
          "--network-secret" "$NETWORK_SECRET"
          "--relay-network-whitelist" "$NETWORK_NAME"
        ]
        (lib.concatMap (peer: [ "-p" peer ]) cfg.peers)
        (lib.concatMap (route: [ "-n" route ]) cfg.routes)
        cfg.extraArgs
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
