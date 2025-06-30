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

        # : System
        smartd.enable = false;
        nut.enable = false;

        # : K8S related
        forgejo.enable = true;
        meshcentral.enable = true;
        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
        };
        nfs4 = {
          enable = true;
          exports.default = {
            path = "/var/lib/backup/nfs";
            subnet = "172.19.82.0/24";
          };
        };
        talos.api.enable = true;
        zotregistry.enable = true;

        # : LAB
        home-assistant.enable = false;
        kms.enable = false;
        netbox = {
          enable = false;
          domain = "box.htkrail.com";
          internal = true;
        };
        unifi-controller.enable = false;
      };
    };
  };
}
