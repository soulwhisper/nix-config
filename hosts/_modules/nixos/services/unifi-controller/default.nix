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
in
{
  options.modules.services.unifi-controller = {
    enable = lib.mkEnableOption "unifi-controller";
  };

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."unifi.noirprime.com".extraConfig = ''
      handle {
	      reverse_proxy localhost:8443 {
          transport http {
            tls_insecure_skip_verify
          }
        }
      }
    '';

    networking.firewall.allowedTCPPorts = [ 8080 8443 8880 8843 6789 ];
    networking.firewall.allowedUDPPorts = [ 3478 10001 ];

    services.unifi = {
      enable = true;
      unifiPackage = pkgs.unstable.unifi;
    };
  };
}
