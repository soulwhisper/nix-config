{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.bind;
  configFile = ./named.conf;
  homeZoneFile = ./homelab.internal.db;
  labZoneFile = ./noirprime.com.db;
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

    systemd.tmpfiles.rules = [
      "d /var/lib/bind 0755 named named - -"
      "C /var/lib/bind/named.conf 0640 named named - ${configFile}"
      "d /var/lib/bind/zones 0755 named named - -"
      "C /var/lib/bind/zones/homelab.internal.db 0640 named named - ${homeZoneFile}"
      "C /var/lib/bind/zones/noirprime.com.db 0640 named named - ${labZoneFile}"
    ];

    services.bind = {
      enable = true;
      directory = "/var/lib/bind";
      configFile = "/var/lib/bind/named.conf";
    };

    # Clean up journal files
    systemd.services.bind = {
      preStart = lib.mkAfter ''
        rm -rf ${config.services.bind.directory}/*.jnl
      '';
    };
  };
}
