{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.isc;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ 67 ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "kea_config" "kea_lease4" ];
      ensureUsers = [
        {
          name = "kea_config";
          ensureDBOwnership = true;
        }
        {
          name = "kea_lease4";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.kea-ctrl-agent.preStart = ''
      mkdir -p /var/lib/kea
      sed -n 's/.*secret "\(.*\)";.*/\1/p' /var/lib/bind/isc.key > /var/lib/kea/isc.secret
      chown kea:kea /var/lib/kea/isc.secret
      chmod 600 /var/lib/kea/isc.secret
    '';

    services.kea = {
      ctrl-agent = {
        enable = true;
        settings = {
          Control-agent = {
            http-host = "0.0.0.0";
            http-port = 53000;
            control-sockets = {
              dhcp4 = {
                socket-type = "unix";
                socket-name = "/var/run/kea/kea4-ctrl-socket";
              };
              dhcp6 = {
                socket-type = "unix";
                socket-name = "/var/run/kea/kea6-ctrl-socket";
              };
              d2 = {
                socket-type = "unix";
                socket-name = "/var/run/kea/kea-ddns-ctrl-socket";
              };
            };
            hooks-libraries = [];
            loggers = [
              {
                name = "kea-ctrl-agent";
                output_options = [
                  {
                    output = "stdout";
                    pattern = "%-5p %m\n";
                  }
                  {
                    output = "/var/log/kea/kea-ctrl-agent.log";
                  }
                ];
                severity = "INFO";
                debuglevel = 0;
              }
            ];
          };
        };
      };
      dhcp-ddns = {
        enable = true;
        settings = {
          DhcpDdns = {
            ip-address = "127.0.0.1";
            port = 53001;
            dns-server-timeout = 100;
            tsig-keys = [
              {
                name = "isc-key";
                algorithm = "hmac-sha256";
                secret = "FILE:/var/lib/kea/isc.secret";
              }
            ];
            forward-ddns = {
              ddns-domains = [
                {
                  name = "homelab.internal.";
                  key-name = "isc-key";
                  dns-servers = [ { ip-address = "127.0.0.1"; port = 53; } ];
                }
              ];
            };
            loggers = [
              {
                name = "kea-dhcp-ddns";
                output_options = [ { output = "stdout"; } ];
                severity = "INFO";
              }
            ];
          };
        };
      };
      dhcp4 = {
        enable = true;
        settings = {
          interfaces-config = {
            interfaces = [ "*" ];
          };
          control-socket = {
            socket-type = "unix";
            socket-name = "/var/run/kea/kea4-ctrl-socket";
          };
          lease-database = {
            type = "postgresql";
            host = "/run/postgresql";
            name = "kea_lease4";
            user = "kea_lease4";
          };
          config-control = {
            config-databases = [{
              type = "postgresql";
              host = "/run/postgresql";
              name = "kea_config";
              user = "kea_config";
            }];
            config-fetch-wait-time = 20;
          };
          dhcp-ddns = {
            enable-updates = true;
            server-ip = "127.0.0.1";
            server-port = 53001;
            ncr-protocol = "UDP";
            ncr-format = "JSON";
          };
          ddns-send-updates = true;
          ddns-override-no-update = true;
          ddns-update-on-renew = true;
          database-retry-config = {
            max-retries = 10;
            retry-interval = 5000;
          };
          renew-timer = 90;
          rebind-timer = 120;
          valid-lifetime = 180;
          expired-leases-processing = {
            reclaim-timer-wait-time = 10;
            flush-reclaimed-timer-wait-time = 25;
            hold-reclaimed-time = 3600;
            max-reclaim-leases = 100;
            max-reclaim-time = 250;
          };
          hooks-libraries = [
            { library = "${pkgs.kea}/lib/kea/hooks/libdhcp_lease_cmds.so"; }
            { library = "${pkgs.kea}/lib/kea/hooks/libdhcp_stat_cmds.so"; }
            { library = "${pkgs.kea}/lib/kea/hooks/libdhcp_pgsql.so"; }
            {
              library = "${pkgs.kea}/lib/kea/hooks/libdhcp_legal_log.so";
              parameters = {
                path = "/var/log/kea";
                base-name = "kea-legal-log";
              };
            }
          ];
          subnet4 = [
            {
              id = 1;
              subnet = "10.10.0.0/24";
              ddns-qualifying-suffix = "homelab.internal.";
              pools = [{ pool = "10.10.0.101 - 10.10.0.250"; }];
              option-data = [
                { name = "routers"; data = "10.10.0.1"; }
                { name = "domain-name-servers"; data = "10.10.0.254"; }
              ];
              reservations = [
                { hw-address = "08:00:27:00:00:01"; ip-address = "10.10.0.50"; hostname = "printer-01"; }
              ];
            }
            {
              id = 2;
              subnet = "10.0.10.0/24";
              ddns-qualifying-suffix = "homelab.internal.";
              pools = [{ pool = "10.0.10.101 - 10.0.10.250"; }];
              option-data = [
                { name = "routers"; data = "10.0.10.1"; }
                { name = "domain-name-servers"; data = "10.0.10.254"; }
              ];
              reservations = [
                { hw-address = "08:00:27:00:00:02"; ip-address = "10.0.10.60"; hostname = "nas-server"; }
              ];
            }
            {
              id = 3;
              subnet = "10.20.0.0/24";
              ddns-qualifying-suffix = "homelab.internal.";
              pools = [{ pool = "10.20.0.101 - 10.20.0.250"; }];
              option-data = [
                { name = "routers"; data = "10.20.0.1"; }
                { name = "domain-name-servers"; data = "10.20.0.254"; }
              ];
            }
            {
              id = 4;
              subnet = "10.20.10.0/24";
              ddns-qualifying-suffix = "homelab.internal.";
              pools = [{ pool = "10.20.10.101 - 10.20.10.250"; }];
              option-data = [
                { name = "routers"; data = "10.20.10.1"; }
                { name = "domain-name-servers"; data = "10.20.10.254"; }
              ];
              reservations = [
                { client-id = "01:aa:bb:cc:dd:ee:ff"; ip-address = "10.20.10.99"; }
              ];
            }
          ];
          loggers = [{
            name = "kea-dhcp4";
            severity = "INFO";
            output_options = [{ output = "stdout"; }];
          }];
        };
      };
    };
  };
}
