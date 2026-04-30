{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.isc;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 9205 ];

    systemd.tmpfiles.rules = [
      "d /var/lib/stork 0755 appuser appuser - -"
    ];

    modules.services.podman.enable = true;
    systemd.services.podman-stork-database.serviceConfig.RestartSec = 5;
    systemd.services.podman-stork-server.serviceConfig.RestartSec = 5;
    systemd.services.podman-stork-agent.serviceConfig.RestartSec = 5;

    virtualisation.oci-containers.containers = {
      "stork-database" = {
        autoStart = true;
        image = "postgres:18-alpine";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        extraOptions = [ "--user 1001:1001" ];
        ports = [
          "15432:5432/tcp"
        ];
        volumes = [
          "/var/lib/stork:/var/lib/postgresql"
        ];
        environment = {
          POSTGRES_DB = "stork";
          POSTGRES_USER = "stork";
          POSTGRES_PASSWORD = "stork";
        };
      };
      "stork-server" = {
        autoStart = true;
        image = "ghcr.io/soulwhisper/stork:latest";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        ports = [
          "9205:9205/tcp"
        ];
        environment = {
          STORK_MODE = "server";
          STORK_REST_PORT = "9205";
          STORK_DATABASE_HOST = "host.containers.internal:15432";
          STORK_DATABASE_NAME = "stork";
          STORK_DATABASE_USER_NAME = "stork";
          STORK_DATABASE_PASSWORD = "stork";
          STORK_SERVER_ENABLE_METRICS = "1";
        };
      };
      "stork-agent" = {
        autoStart = true;
        image = "ghcr.io/soulwhisper/stork:latest";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        extraOptions = [ "--pid=host" ];
        capabilities = { CAP_SYS_PTRACE = true;};
        ports = [
          "9206:9206/tcp"
          "9547:9547/tcp" # kea metrics
          "9119:9119/tcp" # bind9 metrics
        ];
        volumes = [
          "/var/lib/bind:/etc/bind"
          "/var/lib/kea:/var/lib/kea"
          "/run/kea:/run/kea"
        ];
        environment = {
          STORK_MODE = "agent";
          STORK_AGENT_PORT = "9206";
          STORK_AGENT_SERVER_URL = "http://host.containers.internal:9205";
        };
      };
    };
  };
}
