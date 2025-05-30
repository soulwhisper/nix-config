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

  # spec: 8C16G, 1TB, vsphere VM;

  config = {
    virtualisation.vmware.guest.enable = true;

    modules = {
      services = {
        adguard.enable = true;
        caddy = {
          enable = true;
          cloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };

        ## System ##
        smartd.enable = false;
        nut.enable = false;

        ## K8S:Talos ##
        talos.api.enable = true;

        ## Apps ##
        home-assistant.enable = true;
        kms.enable = true;
        netbox = {
          enable = true;
          domain = "box.htkrail.com";
          internal = true;
        };
        unifi-controller.enable = true;
        zotregistry.enable = true;

        ## Apps:Testing ##
        forgejo.enable = true;

        ## Backup ##
        restic = {
          enable = false;
          endpointFile = config.sops.secrets."backup/restic/endpoint".path;
          credentialFile = config.sops.secrets."backup/restic/auth".path;
          encryptionFile = config.sops.secrets."backup/restic/encryption".path;
        };

        ## Storage ##
        minio = {
          enable = false;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
        };

        nfs4 = {
          enable = false;
          exports.default = {
            path = "/mnt/shared/nfs";
            subnet = "172.19.82.0/24";
          };
        };

        timemachine.enable = false;
      };
    };
  };
}
