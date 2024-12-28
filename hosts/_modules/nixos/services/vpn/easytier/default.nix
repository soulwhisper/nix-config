{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.vpn.easytier;
  settingsFormat = pkgs.formats.yaml { };
in
{
  options.modules.services.vpn.easytier = {
    enable = lib.mkEnableOption "easytier";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # creating tun device by systemd is impossible

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
        "-d"
        "--network-name" "$NETWORK_NAME"
        "--network-secret" "$NETWORK_SECRET"
        "-p" "tcp://public.easytier.top:11010"
        "-n" "172.19.80.0/24"
        "-n" "172.19.82.0/24"
        "--default-protocol" "udp"
        "--disable-ipv6"
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
