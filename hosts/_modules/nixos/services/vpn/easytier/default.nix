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
    dataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0644 root root - -"
    ];

    networking.firewall.allowedTCPPorts = [ 11010 11011 11012 ];
    networking.firewall.allowedUDPPorts = [ 11010 11011 ];

    settings = {
      instance_name = "default";
      dhcp = true;
      listeners = [
        "tcp://0.0.0.0:11010"
        "udp://0.0.0.0:11010"
        "wg://0.0.0.0:11011"
        "ws://0.0.0.0:11011/"
        "wss://0.0.0.0:11012/"
      ];
      exit_nodes = [];
      rpc_portal = "0.0.0.0:15888";
      network_identity = {
        network_name = "homelab";
        network_secret = "${builtins.readFile cfg.authFile}";
      };
      peer = [
        {
          uri = "tcp://public.easytier.top:11010";
        }
      ];
      proxy_network = [
        {
          cidr = "172.16.0.0/12";
        }
        {
          cidr = "10.0.0.0/8";
        }
      ];
      flags = {
        enable_encryption = true;
        enable_ipv6 = false;
        latency_first = false;
      };
    };

    easytier-yaml = settingsFormat.generate "${cfg.dataDir}/config.yaml" settings;

    systemd.services.easytier-server = {
      after = [ "network.target" "syslog.target" ];
      wants = [ "network.targe" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.easytier-custom} -c ${easytier-yaml}";
        WorkingDirectory = "${cfg.dataDir}";
        Restart = "always";
      };
    };
  };
}
