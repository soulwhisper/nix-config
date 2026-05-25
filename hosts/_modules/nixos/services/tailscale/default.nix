{
  config,
  lib,
  ...
}: let
  cfg = config.modules.services.tailscale;
in {
  options.modules.services.tailscale = {
    enable = lib.mkEnableOption "tailscale";
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of subnets to advertise over Tailscale";
    };
    derper = {
      enable = lib.mkEnableOption "tailscale-derper";
      domain = lib.mkOption {
        type = lib.types.str;
        default = "derp.noirprime.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [48484];
    networking.firewall.allowedUDPPorts = [41641 48484];

    # Internet Router must set 'Port Forwarding' for 48484 tcp/udp;

    services.tailscale = {
      enable = true;
      port = 41641;
      openFirewall = false;
      useRoutingFeatures = lib.mkIf (cfg.networks != []) "server";
      extraSetFlags = lib.optionals (cfg.networks != []) [
        "--advertise-routes=${lib.concatStringsSep "," cfg.networks}"
      ];
      derper = {
        enable = cfg.derper.enable;
        domain = cfg.derper.domain;
        port = 48484;
        stunPort = 48484;
        configureNginx = false;
        openFirewall = false;
        verifyClients = true;
      };
    } // lib.optionalAttrs (cfg.authKeyFile != null) {
      authKeyFile = cfg.authKeyFile;
    };
  };
}
