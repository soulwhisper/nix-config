{
  config,
  lib,
  pkgs,
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
    domain = lib.mkOption {
      type = lib.types.str;
      default = "box.noirprime.com";
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9804];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable (
      (lib.optionalString cfg.internal "tls internal\n")
      + ''
        handle_path /static/* {
          root * /var/lib/netbox/static
          encode gzip zstd
          file_server
        }
        handle {
          reverse_proxy localhost:9804
        }
      ''
    );

    # for caddy file_server
    users.users.caddy.extraGroups = ["netbox"];

    # ref:https://github.com/NixOS/nixpkgs/issues/385193
    services.netbox = {
      enable = true;
      port = 9804;
      listenAddress = "[::]";
      secretKeyFile = saltFile;
      plugins = python3Packages:
        with python3Packages; [
          netbox-attachments
          netbox-bgp
          netbox-dns
          netbox-floorplan-plugin
          netbox-interface-synchronization
          netbox-plugin-prometheus-sd
          netbox-qrcode
          netbox-reorder-rack
          netbox-topology-views
        ];
      settings = {
        PLUGINS = [
          "netbox_attachments"
          "netbox_bgp"
          "netbox_dns"
          "netbox_floorplan"
          "netbox_interface_synchronization"
          "netbox_prometheus_sd"
          "netbox_qrcode"
          "netbox_reorder_rack"
          "netbox_topology_views"
        ];
      };
    };
  };
}
