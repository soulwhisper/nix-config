{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.unifi-controller;

  init-mongo = ''
    db.getSiblingDB("unifi-db").createUser({user: "unifi", pwd: "unifi", roles: [{role: "dbOwner", db: "unifi-db"}]});
    db.getSiblingDB("unifi-db_stat").createUser({user: "unifi", pwd: "unifi", roles: [{role: "dbOwner", db: "unifi-db_stat"}]});
  '';
  init-mongo-file = builtins.toFile "init-mongo.js" init-mongo;
in {
  options.modules.services.unifi-controller = {
    enable = lib.mkEnableOption "unifi-controller";
  };

  config = lib.mkIf cfg.enable {
    # use ip:8443 in case network failing.

    networking.firewall.allowedTCPPorts = [8080 8443];
    networking.firewall.allowedUDPPorts = [3478 10001];

    systemd.tmpfiles.rules = [
      "d /var/lib/unifi 0755 appuser appuser - -"
      "d /var/lib/unifi/config 0755 appuser appuser - -"
      "d /var/lib/unifi/data 0755 appuser appuser - -"
    ];

    systemd.services.podman-unifi-controller.serviceConfig.RestartSec = 5;
    systemd.services.podman-unifi-db.serviceConfig.RestartSec = 5;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."unifi-controller" = {
      autoStart = true;
      image = "lscr.io/linuxserver/unifi-network-application:latest";
      extraOptions = ["--pull=newer"];
      dependsOn = ["unifi-db"];
      ports = [
        "8080:8080/tcp"
        "8443:8443/tcp"
        "3478:3478/udp"
        "10001:10001/udp"
      ];
      environment = {
        PUID = "1001";
        PGID = "1001";
        TZ = "Asia/Shanghai";
        MONGO_HOST = "host.containers.internal";
        MONGO_PORT = "27017";
        MONGO_DBNAME = "unifi-db";
        MONGO_USER = "unifi";
        MONGO_PASS = "unifi";
      };
      volumes = [
        "/var/lib/unifi/config:/config"
      ];
    };
    virtualisation.oci-containers.containers."unifi-db" = {
      autoStart = true;
      image = "bitnami/mongodb:7.0";
      extraOptions = ["--pull=newer"];
      ports = [
        "27017:27017/tcp"
      ];
      volumes = [
        "${init-mongo-file}":/docker-entrypoint-initdb.d/init-mongo.js"
        "/var/lib/unifi/data:/bitnami/mongodb"
      ];
    };
  };
}
