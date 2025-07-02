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
        caddy = {
          enable = true;
          cloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };
        easytier.proxy_networks = ["172.19.80.0/24" "172.19.82.0/24"];

        # : System
        smartd.enable = false;
        nut.enable = false;

        # : K8S related
        meshcentral.enable = true;
        minio = {
          enable = false;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
        };
        talos.api.enable = true;
        zotregistry.enable = false;

        # : LAB
        home-assistant.enable = false;
        kms.enable = false;
        netbox = {
          enable = false;
          domain = "box.htkrail.com";
          internal = true;
        };
        unifi-controller.enable = false;

        # : Others
        nfs4 = {
          enable = false;
          exports.default = {
            path = "/var/lib/backup/nfs";
            subnet = "172.19.82.0/24";
          };
        };
      };
    };
  };
}
