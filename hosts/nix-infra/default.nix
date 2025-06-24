{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  # spec: 4C8G, 100GB, proxmox VM;

  config = {
    services.qemuGuest.enable = true;

    modules = {
      services = {
        adguard.enable = true;
        caddy = {
          enable = true;
          cloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };
        easytier.proxy_networks = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];

        ## K8S:Talos ##
        talos.api.enable = true;

        ## Apps:Home ##
        home-assistant.enable = true;
        kms.enable = true;
        meshcentral.enable = true;
        unifi-controller.enable = true;

        ## Apps:DevOps ##
        netbox.enable = false;
        postgres.enable = true;
      };
    };
  };
}
