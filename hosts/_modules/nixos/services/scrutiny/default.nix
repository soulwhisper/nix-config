{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.scrutiny;
in {
  options.modules.services.scrutiny = {
    enable = lib.mkEnableOption "scrutiny";
    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/dev/sda" ];
      example = [ "/dev/sda" "/dev/sdb" ];
      description = "List of block devices to monitor with Scrutiny.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9204];

    # switch to well-maintained fork

    systemd.services.podman-scrutiny.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."scrutiny" = {
      autoStart = true;
      image = "ghcr.io/starosdev/scrutiny:latest";
      labels = {
        "io.containers.autoupdate" = "registry";
      };
      capabilities = {
        SYS_ADMIN = true;
        SYS_RAWIO = true;
      };
      ports = [
        "9204:8080/tcp"
        # "8086:8086/tcp"
      ];
      volumes = [
        "/run/udev:/run/udev:ro"
        "/var/lib/scrutiny/config:/opt/scrutiny/config"
        "/var/lib/scrutiny/influxdb:/opt/scrutiny/influxdb"
      ];
      devices = builtins.map (dev: "${dev}:${dev}") cfg.devices;
    };
  };
}
