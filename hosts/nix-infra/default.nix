{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  # spec: 4C8G, 500GB, ESXi VM;

  config = {
    # services.qemuGuest.enable = true;
    virtualisation.vmware.guest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = true;
        caddy = {
          enable = true;
          cloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };
        easytier.proxy_networks = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];

        # : K8S related
        meshcentral.enable = false;
        talos.api.enable = false;

        # : LAB
        emby.enable = true; # sub=movie
        freshrss.enable = true; # sub=rss
        freshrss.authFile = config.sops.secrets."apps/default/auth".path;
        home-assistant.enable = true; # sub=hass
        immich.enable = true; # sub=photo
        karakeep.enable = true; # sub=bookmarks
        kms.enable = true;
        moviepilot.enable = true; # sub=pilot
        moviepilot.authFile = config.sops.secrets."apps/moviepilot/auth".path;
        n8n.enable = true; # sub=n8n
        netbox.enable = true; # sub=box
        qbittorrent.enable = true; # sub=bt
        unifi-controller.enable = true; # sub=unifi
      };
    };
  };
}
