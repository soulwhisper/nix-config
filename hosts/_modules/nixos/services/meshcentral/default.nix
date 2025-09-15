{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.meshcentral;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.meshcentral = {
    enable = lib.mkEnableOption "meshcentral";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "mesh.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      4433
      (lib.mkIf (!reverseProxyCaddy.enable) 9203)
    ];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9203
      }
    '';

    # nix package is outdated, use container instead

    systemd.tmpfiles.rules = [
      "d /var/lib/meshcentral 0755 root root - -"
      "C /var/lib/meshcentral/config.json 0644 root root - ${./config.json}"
    ];

    systemd.services.podman-meshcentral.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."meshcentral" = {
      autoStart = true;
      image = "ghcr.io/ylianst/meshcentral:latest";
      extraOptions = ["--pull=newer"];
      ports = [
        "4433:4433/tcp"
        "9203:80/tcp"
      ];
      volumes = [
        "/var/lib/meshcentral:/opt/meshcentral/meshcentral-data"
      ];
    };
  };
}
