{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.crafty;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.crafty = {
    enable = lib.mkEnableOption "crafty";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "mc.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9808];
    networking.firewall.allowedTCPPortRanges = [
      {
        from = 25500;
        to = 25600;
      }
    ];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy https://localhost:9808 {
		      transport http {
			      tls_insecure_skip_verify
		      }
        }
      }
    '';

    # admin:pass, cat /var/lib/crafty/config/default-creds.txt

    systemd.tmpfiles.rules = [
      "d /var/lib/crafty 0755 appuser appuser - -"
      "d /var/lib/crafty/backups 0755 appuser appuser - -"
      "d /var/lib/crafty/config 0755 appuser appuser - -"
      "d /var/lib/crafty/import 0755 appuser appuser - -"
      "d /var/lib/crafty/logs 0755 appuser appuser - -"
      "d /var/lib/crafty/servers 0755 appuser appuser - -"
    ];

    systemd.services.podman-crafty.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."crafty" = {
      autoStart = true;
      image = "registry.gitlab.com/crafty-controller/crafty-4:latest";
      extraOptions = ["--pull=newer"];
      ports = [
        "9808:8443/tcp"
        "25500-25600:25500-25600"
      ];
      environment = {
        UID = "1001";
        GID = "1001";
        TZ = "Asia/Shanghai";
      };
      volumes = [
        "/var/lib/crafty/config:/crafty/app/config"
        "/var/lib/crafty/backups:/crafty/backups"
        "/var/lib/crafty/import:/crafty/import"
        "/var/lib/crafty/logs:/crafty/logs"
        "/var/lib/crafty/servers:/crafty/servers"
      ];
    };
  };
}
