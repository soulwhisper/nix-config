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
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--no-tun"
        "--socks5 1081"
        "-d"
        "-n 172.16.0.0/12"
        "-n 10.0.0.0/8"
        "-p tcp://public.easytier.top:11010"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 11010 11011 11012 1081 ];
    networking.firewall.allowedUDPPorts = [ 11010 11011 ];

    systemd.services.easytier = {
      after = [ "network.target" "syslog.target" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = [
            "/bin/sh -c 'mkdir -p /var/lib/easytier'"
          ];
        ExecStart = lib.concatStringsSep " " (
          [
            "${lib.getExe pkgs.easytier-custom}"
            "--network-name {$NETWORK_NAME}"
            "--network-secret {$NETWORK_SECRET}"
          ]
          ++ cfg.extraArgs
        );
        WorkingDirectory = "/var/lib/easytier";
        EnvironmentFile = "${cfg.authFile}";
        Restart = "always";
      };
    };
  };
}
