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

  config = {
    services.qemuGuest.enable = true; # for proxmox

    modules = {
      services = {
        easytier.proxy_networks = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];

        adguard.enable = true;
        caddy = {
          enable = true;
          CloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };

        ## K8S:Talos ##
        talos.api.enable = true;

        ## Apps ##
        glance.enable = true;
        home-assistant.enable = true;
        home-assistant.sgcc.authFile = config.sops.secrets."apps/hass-sgcc/auth".path;
        kms.enable = true;
        netbox.enable = true;
        unifi-controller.enable = true;

        ## Storage ##
        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
        };
      };
    };
  };
}
