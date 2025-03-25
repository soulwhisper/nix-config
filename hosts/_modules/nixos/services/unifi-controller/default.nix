{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.unifi-controller;
in {
  options.modules.services.unifi-controller = {
    enable = lib.mkEnableOption "unifi-controller";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/unifi";
    };
  };

  config = lib.mkIf cfg.enable {
    # use ip:8443 in case network failing.

    networking.firewall.allowedTCPPorts = [8080 8443];
    networking.firewall.allowedUDPPorts = [3478 10001];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 unifi unifi - -"
      "L /var/lib/unifi - - - - ${cfg.dataDir}"
    ];

    # use same parameters in "lscr.io/linuxserver/unifi-network-application:latest"
    services.unifi = {
      enable = true;
      mongodbPackage = pkgs.mongodb-ce;
      initialJavaHeapSize = 1024;
      maximumJavaHeapSize = 1024;
      extraJvmOptions = [
        "-Dlog4j2.formatMsgNoLookups=true"
        "-Dfile.encoding=UTF-8"
        "-Djava.awt.headless=true"
        "-Dapple.awt.UIElement=true"
        "-XX:+UseParallelGC"
        "-XX:+ExitOnOutOfMemoryError"
        "-XX:+CrashOnOutOfMemoryError"
      ];
    };
  };
}
