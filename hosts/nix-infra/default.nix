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
        mihomo.enable = true;

        ## K8S:Talos ##
        talos.api.enable = true;
        mihomo.enable = true;
        mihomo.authFile = config.sops.secrets."networking/mihomo/auth".path;

        ## Apps:Home ##
        home-assistant.enable = true;
        kms.enable = true;
        unifi-controller.enable = true;

        ## Apps:DevOps ##
        netbox.enable = false;
      };
    };
  };
}
