{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.homebridge;
in {
  options.modules.services.homebridge = {
    enable = lib.mkEnableOption "homebridge";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/homebridge";
    };
  };
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [8581];
    networking.firewall.allowedUDPPorts = [5353];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root - -"
    ];

    # systemctl status podman-homebridge.service
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."homebridge" = {
      autoStart = true;
      image = "homebridge/homebridge:latest";
      extraOptions = ["--network=host"];
      volumes = [
        "${cfg.dataDir}:/homebridge"
      ];
    };
  };
}
