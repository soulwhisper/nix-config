{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.home-assistant;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [5580];
    networking.firewall.allowedUDPPorts = [5353];
    # udp 32768-65535 is enabled at core;

    networking.enableIPv6 = true;

    services.home-assistant.extraComponents = [
      "matter"
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/matter 0755 appuser appuser - -"
    ];

    # systemctl status podman-hass-matter-server.service
    ## https://github.com/home-assistant-libs/python-matter-server/blob/main/docs/docker.md
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."hass-matter-server" = {
      autoStart = true;
      image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
      extraOptions = ["--network=host"];
      volumes = [
        "${cfg.dataDir}/matter:/data"
      ];
    };
  };
}
