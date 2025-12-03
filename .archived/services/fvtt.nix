{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.fvtt;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.fvtt = {
    enable = lib.mkEnableOption "fvtt";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "fvtt.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [30000];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:30000
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/fvtt 0755 1000 root - -"
    ];

    # authfile include 'FOUNDRY_ADMIN_KEY', 'FOUNDRY_USERNAME' and 'FOUNDRY_PASSWORD'

    systemd.services.podman-fvtt.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."fvtt" = {
      autoStart = true;
      image = "felddy/foundryvtt:release";
      pull = "newer";
      ports = [
        "30000:30000/tcp"
      ];
      environment =
        {
          TZ = "Asia/Shanghai";
        }
        // lib.optionalAttrs (reverseProxyCaddy.enable) {
          FOUNDRY_HOSTNAME = "${cfg.domain}";
          FOUNDRY_PROXY_PORT = "443";
          FOUNDRY_PROXY_SSL = "true";
        };
      environmentFiles = [
        "${cfg.authFile}"
      ];
      volumes = [
        "/var/lib/fvtt:/data"
      ];
    };
  };
}
