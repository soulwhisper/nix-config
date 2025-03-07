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
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/netbox";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9201];

    services.caddy.virtualHosts."box.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle_path /static/* {
        root * /var/lib/netbox/static
        encode gzip zstd
        file_server
      }
      handle {
        reverse_proxy localhost:9201
      }
    '';

    # backup postgres database
    services.postgresqlBackup.databases = ["netbox"];

    # for caddy file_server
    users.users.caddy.extraGroups = ["netbox"];

    # nixos-24.11 => 4.1.x
    ## https://github.com/NixOS/nixpkgs/issues/385193; before fixed
    services.netbox = {
      enable = true;
      port = 9201;
      listenAddress = "[::]";
      secretKeyFile = saltFile;
      plugins = python3Packages:
        with python3Packages; [
          netbox-bgp
          netbox-dns
          (netbox-documents.overridePythonAttrs {
            dependencies = [
              (drf-extra-fields.overridePythonAttrs (previous: {
                dependencies = previous.dependencies ++ [pytz];
                disabledTests = [
                  "test_create"
                  "test_create_with_base64_prefix"
                  "test_create_with_webp_image"
                  "test_remove_with_empty_string"
                ];
              }))
            ];
          })
          (netbox-floorplan-plugin.overridePythonAttrs (previous: {
            version = "0.5.0";
            src = previous.src.override {
              tag = "0.5.0";
              hash = "sha256-tN07cZKNBPraGnvKZlPEg0t8fusDkBc2S41M3f5q3kc=";
            };
          }))
          netbox-interface-synchronization
          netbox-plugin-prometheus-sd
          netbox-qrcode
          netbox-reorder-rack
          netbox-topology-views
        ];
      settings = {
        PLUGINS = [
          "netbox_bgp"
          "netbox_dns"
          "netbox_documents"
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
