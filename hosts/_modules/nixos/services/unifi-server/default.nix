{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.unifi-server;
in {
  options.modules.services.unifi-server = {
    enable = lib.mkEnableOption "unifi-server";
    ip = lib.mkOption {
      type = lib.types.str;
      description = "UOS_SYSTEM_IP";
    };
  };

  config = lib.mkIf cfg.enable {
    # conflict with unifi-network
    # use ip:9801 in case network failing

    networking.firewall.allowedTCPPorts = [9801 8080 8443 8444 5005 9543 6789 11084 5671 8880 8881 8882];
    networking.firewall.allowedUDPPorts = [3478 10003 5514];

    systemd.tmpfiles.rules = [
      "d /var/lib/unifi-server/persistent 0755 root root - -"
      "d /var/lib/unifi-server/log 0755 root root - -"
      "d /var/lib/unifi-server/data 0755 root root - -"
      "d /var/lib/unifi-server/srv 0755 root root - -"
      "d /var/lib/unifi-server/lib 0755 root root - -"
      "d /var/lib/unifi-server/mongodb 0755 root root - -"
      "d /var/lib/unifi-server/rabbitmq 0755 root root - -"
    ];

    systemd.services.podman-unifi-server.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."unifi-server" = {
      autoStart = true;
      image = "ghcr.io/lemker/unifi-os-server:latest";
      pull = "newer";
      privileged = true;
      extraOptions = ["--memory=4g"];
      ports = [
        "9801:443/tcp" # web-ui
        "8080:8080/tcp" # unifi-os-server-communication-svc
        "3478:3478/udp" # unifi-os-server-stun-svc
        "10003:10003/udp" # unifi-os-server-discovery-svc
        "5514:5514/udp" # Opt. unifi-os-server-syslog-svc
        "8443:8443/tcp" # Opt. unifi-os-server-network-app-svc
        "8444:8444/tcp" # Opt. unifi-os-server-hotspot-secured-svc
        "5005:5005/tcp" # Opt. unifi-os-server-rtp-svc
        "9543:9543/tcp" # Opt. unifi-os-server-id-hub-svc
        "6789:6789/tcp" # Opt. unifi-os-server-mobile-speedtest-svc
        "11084:11084/tcp" # Opt. unifi-os-server-site-supervisor-svc
        "5671:5671/tcp" # Opt. unifi-os-server-aqmps-svc
        "8880:8880/tcp" # Opt. unifi-os-server-hotspot-redirect-0-svc
        "8881:8881/tcp" # Opt. unifi-os-server-hotspot-redirect-1-svc
        "8882:8882/tcp" # Opt. unifi-os-server-hotspot-redirect-2-svc
      ];
      environment = {
        UOS_SYSTEM_IP = "${cfg.ip}";
      };
      volumes = [
        "/var/lib/unifi-server/persistent:/persistent"
        "/var/lib/unifi-server/log:/var/log"
        "/var/lib/unifi-server/data:/data"
        "/var/lib/unifi-server/srv:/srv"
        "/var/lib/unifi-server/lib:/var/lib/unifi"
        "/var/lib/unifi-server/mongodb:/var/lib/mongodb"
        "/var/lib/unifi-server/rabbitmq:/etc/rabbitmq/ssl"
      ];
    };
  };
}
