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

  # spec: 4C8G, 1TB, ESXi VM;

  config = {
    # This is a must if "/home" is isolated from "/", for sops.
    fileSystems."/home".neededForBoot = true;

    # services.qemuGuest.enable = true;
    virtualisation.vmware.guest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = true;
        caddy.enable = true;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;
        easytier.proxy_networks = ["172.19.80.0/24" "172.19.82.0/24"];

        # : System
        smartd.enable = false;
        nut.enable = false;

        # : K8S related
        meshcentral.enable = true; # sub=mesh
        talos.api.enable = true;
        versitygw.enable = true; # sub=s3
        versitygw.authFile = config.sops.secrets."storage/versitygw/auth".path;
        zotregistry.enable = true; # sub=zot

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

        # : Tests
        crafty.enable = true; # sub=mc

        # : Others
        nfs4 = {
          enable = false;
          exports.default = {
            path = "/var/lib/shared";
            subnet = "172.19.82.0/24";
          };
        };
        timemachine.enable = false;
      };
    };
  };
}
