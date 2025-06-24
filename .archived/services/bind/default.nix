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

  # this service act as internal authoritative server
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [5300 9202];
    networking.firewall.allowedUDPPorts = [5300];

    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    # if need dynamics, check:https://github.com/11notes/docker-bind
    environment.etc = {
      "cfgs/bind/namd.conf" = {
        source = ./named.conf;
        user = "named";
        group = "named";
        mode = "0640";
      };
      "cfgs/bind/homelab.internal.db" = {
        source = ./homelab.internal.db;
        user = "named";
        group = "named";
        mode = "0640";
      };
      "cfgs/bind/noirprime.com.db" = {
        source = ./noirprime.com.db;
        user = "named";
        group = "named";
        mode = "0640";
      };
    };

    services.bind = {
      enable = true;
      directory = "/etc/cfgs/bind";
      configFile = "/etc/cfgs/bind/namd.conf";
    };

    # Clean up journal files
    systemd.services.bind = {
      preStart = lib.mkAfter ''
        rm -rf ${config.services.bind.directory}/*.jnl
      '';
    };
  };
}
