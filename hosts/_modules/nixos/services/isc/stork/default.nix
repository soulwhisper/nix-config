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
      "d /var/lib/stork 0755 root root - -"
      "d /var/lib/stork/conf.d 0755 root root - -"
    ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "stork" ];
      ensureUsers = [
        {
          name = "stork";
          ensureDBOwnership = true;
        }
      ];
    };

    modules.services.podman.enable = true;
    systemd.services.podman-stork-webui.serviceConfig.RestartSec = 5;
    systemd.services.podman-stork-server.serviceConfig.RestartSec = 5;
    systemd.services.podman-stork-agent-kea.serviceConfig.RestartSec = 5;

    virtualisation.oci-containers.containers = {
      "stork-server" = {
        autoStart = true;
        image = "registry.gitlab.isc.org/isc-projects/stork/server:latest";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        ports = [
          "53100:53100/tcp"
        ];
        volumes = [
          "/var/lib/stork:/etc/supervisor"
        ];
        environment = {
          STORK_DATABASE_HOST = "/run/postgresql";
          STORK_DATABASE_NAME = "stork";
          STORK_DATABASE_USER_NAME = "stork";
          STORK_REST_HOST = "0.0.0.0";
          STORK_REST_PORT = "53100";
          STORK_SERVER_ENABLE_METRICS = "1";
        };
      };
      "stork-agent" = {
        autoStart = true;
        image = "registry.gitlab.isc.org/isc-projects/stork/agent:latest";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        ports = [
          "53101:53101/tcp"
          "9547:9547/tcp" # kea metrics
          "9119:9119/tcp" # bind9 metrics
        ];
        volumes = [
          "/run/named:/run/named:ro"
          "/run/kea:/run/kea:ro"
        ];
        environment = {
          STORK_AGENT_HOST = "0.0.0.0";
          STORK_AGENT_PORT = "53101";
        };
      };
      "stork-webui" = {
        autoStart = true;
        image = "registry.gitlab.isc.org/isc-projects/stork/webui:latest";
        labels = {
          "io.containers.autoupdate" = "registry";
        };
        ports = [
          "9205:8080/tcp"
        ];
        environment = {
          API_HOST = "host.containers.internal";
          API_PORT = "53100";
        };
      };
    };
  };
}
