{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.keycloak;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.keycloak = {
    enable = lib.mkEnableOption "keycloak";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9800];

    services.caddy.virtualHosts."auth.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9800
      }
    '';

    # persist postgres data
    modules.services.postgresql.enable = true;

    services.keycloak = {
      enable = true;
      initialAdminPassword = "keycloak";
      settings = {
        hostname-backchannel-dynamic = true;
        hostname = "auth.noirprime.com";
        http-host = "0.0.0.0";
        http-port = 9800;
      };
    };
  };
}
