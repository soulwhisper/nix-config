{
  config,
  lib,
  ...
}: let
  cfg = config.modules.services.tailscale;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.tailscale = {
    enable = lib.mkEnableOption "tailscale";
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "derp.noirprime.com";
    };
    networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of subnets to advertise over Tailscale";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [3478 41641];

    # Internet Router must set 'Port Forwarding' for 443/3478/41641;

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:8010
      }
    '';

    services.tailscale = {
      enable = true;
      port = 41641;
      openFirewall = false;
      useRoutingFeatures = lib.mkIf (cfg.networks != []) "server";
      extraSetFlags = lib.optionals (cfg.networks != []) [
        "--advertise-routes=${lib.concatStringsSep "," cfg.networks}"
      ];
      derper = {
        enable = true;
        configureNginx = false;
        openFirewall = false;
        verifyClients = true;
      };
    } // lib.optionalAttrs (cfg.authKeyFile != null) {
      authKeyFile = cfg.authKeyFile;
    };
  };
}
