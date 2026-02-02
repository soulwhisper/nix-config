{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.dockge;
in {
  options.modules.services.dockge = {
    enable = lib.mkEnableOption "dockge";
  };

  # This service only for test, not recommended for production
  # containers need to set firewall or reverseProxy afterwards

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9800];

    systemd.tmpfiles.rules = [
      "d /var/lib/dockge/data 0755 root root - -"
      "d /var/lib/dockge/stacks 0755 root root - -"
    ];

    systemd.services.podman-dockge.serviceConfig.RestartSec = 5;
    # users.users.appuser.extraGroups = [ "podman" ];

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."dockge" = {
      autoStart = true;
      image = "louislam/dockge:latest";
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      ports = [
        "9800:5001/tcp"
      ];
      environment = {
        DOCKGE_STACKS_DIR = "/app/stacks";
      };
      volumes = [
        "/run/docker.sock:/var/run/docker.sock"
        "/var/lib/dockge/data:/app/data"
        "/var/lib/dockge/stacks:/app/stacks"
      ];
    };
  };
}
