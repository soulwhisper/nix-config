# visit: localhost:8443
# data: /var/lib/unifi/data

{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.unifi-controller;

  init-mongo = ''
      db.getSiblingDB("unifi-db").createUser({user: "unifi", pwd: "unifi", roles: [{role: "dbOwner", db: "unifi-db"}]});
      db.getSiblingDB("unifi-db_stat").createUser({user: "unifi", pwd: "unifi", roles: [{role: "dbOwner", db: "unifi-db_stat"}]});
    '';
  init-mongo-file = builtins.toFile "init-mongo.js" init-mongo;
in
{
  options.modules.services.unifi-controller = {
    enable = lib.mkEnableOption "unifi-controller";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/unifi-controller";
    };
  };

  config = lib.mkIf cfg.enable {
    # use ip:8443 in case network failing.

    networking.firewall.allowedTCPPorts = [ 8080 8443 ];
    networking.firewall.allowedUDPPorts = [ 3478 10001 ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "d ${cfg.dataDir}/config 0755 appuser appuser - -"
      "d ${cfg.dataDir}/data 0755 appuser appuser - -"
      "L+ ${cfg.dataDir}/init-mongo.js 0600 appuser appuser - ${init-mongo-file}"
    ];

    # systemctl status podman-unifi-controller.service
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."unifi-controller" = {
      autoStart = true;
      image = "lscr.io/linuxserver/unifi-network-application:latest";
      dependsOn = [ "unifi-db" ];
      ports = [
        "8080:8080/tcp"
        "8443:8443/tcp"
        "3478:3478/udp"
        "10001:10001/udp"
      ];
      environment = {
        PUID="1001";
        PGID="1001";
        TZ="Asia/Shanghai";
        MONGO_HOST="host.containers.internal";
        MONGO_PORT="27017";
        MONGO_DBNAME="unifi-db";
        MONGO_USER="unifi";
        MONGO_PASS="unifi";
      };
      volumes = [
        "${cfg.dataDir}/config:/config"
      ];
    };
    virtualisation.oci-containers.containers."unifi-db" = {
      autoStart = true;
      image = "bitnami/mongodb:7.0";
      ports = [
        "27017:27017/tcp"
      ];
      volumes = [
        "${cfg.dataDir}/init-mongo.js:/docker-entrypoint-initdb.d/init-mongo.js"
        "${cfg.dataDir}/data:/bitnami/mongodb"
      ];
    };
  };
}
