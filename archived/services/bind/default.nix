{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.bind;
in {
  options.modules.services.bind = {
    enable = lib.mkEnableOption "bind";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [53];
    networking.firewall.allowedUDPPorts = [53];

    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    environment.etc = {
      "bind/namd.conf" = {
        source = ./named.conf;
        user = "named";
        group = "named";
        mode = "0640";
      };
      "bind/homelab.internal.zone" = {
        source = ./homelab.internal.zone;
        user = "named";
        group = "named";
        mode = "0640";
      };
      "bind/noirprime.com.zone" = {
        source = ./noirprime.com.zone;
        user = "named";
        group = "named";
        mode = "0640";
      };
    };

    services.bind = {
      enable = true;
      directory = "/etc/bind";
      configFile = "/etc/bind/namd.conf";
    };

    # Clean up journal files
    systemd.services.bind = {
      preStart = lib.mkAfter ''
        rm -rf ${config.services.bind.directory}/*.jnl
      '';
    };
  };
}
