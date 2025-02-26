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
      default = "/opt/backup/netbox";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9203];

    services.caddy.virtualHosts."box.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle_path /static/* {
        root * /var/lib/netbox/static
        encode gzip zstd
        file_server
      }
      handle {
        reverse_proxy localhost:9203
      }
    '';

    # backup postgres database
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 root root - -"
    ];
    services.postgresqlBackup = {
      enable = true;
      databases = ["netbox"];
    };
    modules.services.bindfs.netbox-backup = {
      source = "${cfg.dataDir}";
      dest = "/var/backup/postgresql";
      extraArgs = ["--mirror-only=postgres"];
    };
    # for caddy file_server
    users.users.caddy.extraGroups = [ "netbox" ];

    services.netbox = {
      enable = true;
      port = 9203;
      listenAddress = "[0.0.0.0]";
      secretKeyFile = saltFile;
      plugins = python3Packages:
        with python3Packages; [
          netbox-bgp
          netbox-dns
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
