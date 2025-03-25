{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.netbird;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.netbird = {
    enable = lib.mkEnableOption "netbird";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/netbird";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [51820]; # wireguard

    services.caddy.virtualHosts."vpn.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      import security_headers
      handle_path /signalexchange.SignalExchange/* {
        reverse_proxy h2c://localhost:9803
      }
      handle_path /api/* {
        reverse_proxy localhost:9802
      }
      handle_path /management.ManagementService/* {
        reverse_proxy h2c://localhost:9802
      }
      handle {
        root * ${config.services.netbird.server.dashboard.finalDrv}
        encode gzip zstd
        file_server
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 netbird netbird - -"
      "L /var/lib/netbird-mgmt - - - - ${cfg.dataDir}"
    ];

    # for caddy file_server
    users.users.caddy.extraGroups = ["netbird"];

    # remap coturn ports
    services.coturn.listening-port = 3479;

    services.netbird = {
      enable = true;
      server = {
        enable = true;
        enableNginx = false;
        domain = "vpn.noirprime.com";
        dashboard.managementServer = "http://vpn.noirprime.com";
        management = {
          port = 9802;
          metricsPort = 9105;
          dnsDomain = "noirprime.com";
          settings = {
            TURNConfig = {
              Stuns = lib.mkDefault [
                {
                  Proto = "udp";
                  URI = "stun:vpn.noirprime.com:3479";
                  Username = "";
                  Password = null;
                }
              ];
            };
          };
        };
        signal = {
          port = 9803;
          metricsPort = 9106;
        };
        coturn = {
          enable = true;
          password = "netbird";
        };
      };
      tunnels."default" = {
        port = 51820;
      };
    };
  };
}