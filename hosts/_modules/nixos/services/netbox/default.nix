{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.netbox;
  reverseProxyCaddy = config.modules.services.caddy;

  salt = builtins.substring 0 50 (builtins.hashString "sha256" config.networking.hostName);
  saltFile = pkgs.writeTextFile {
    name = "netbox_salt";
    text = salt;
  };
in {
  options.modules.services.netbox = {
    enable = lib.mkEnableOption "netbox";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/netbox";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9203];

    services.caddy.virtualHosts."box.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9203
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "d ${cfg.dataDir}/db 0755 appuser appuser - -"
    ];

    services.postgresql.dataDir = "${cfg.dataDir}/db";
    systemd.services.postgresql.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.postgresql.serviceConfig.Group = lib.mkForce "appuser";

    systemd.services.netbox.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.netbox.serviceConfig.Group = lib.mkForce "appuser";
    systemd.services.netbox-rq.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.netbox-rq.serviceConfig.Group = lib.mkForce "appuser";

    services.netbox = {
      enable = true;
      port = 9203;
      dataDir = "${cfg.dataDir}";
      listenAddress = "[0.0.0.0]";
      secretKeyFile = saltFile;
      plugins = python3Packages: with python3Packages; [
        netbox-bgp
        netbox-dns
        netbox-documents
        netbox-floorplan-plugin
        netbox-interface-synchronization
        netbox-napalm-plugin
        netbox-plugin-prometheus-sd
        netbox-qrcode
        netbox-reorder-rack
        netbox-topology-views
      ];
    };
  };
}
