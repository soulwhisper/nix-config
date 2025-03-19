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
    modules = {
      filesystems.zfs = {
        enable = true;
        mountPoolsAtBoot = [
          "numina"
        ];
      };

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
        glance.enable = true;
        kms.enable = true;
        unifi-controller.enable = true;
        home-assistant = {
          enable = true;
          dataDir = "/numina/apps/home-assistant";
          sgcc.authFile = config.sops.secrets."apps/hass-sgcc/auth".path;
        };
        netbox = {
          enable = true;
          dataDir = "/numina/apps/netbox";
        };
        zotregistry = {
          enable = true;
          dataDir = "/numina/apps/zot";
        };
        forgejo = {
          enable = true;
          dataDir = "/numina/apps/forgejo";
        };
        woodpecker = {
          enable = true;
          dataDir = "/numina/apps/woodpecker";
        };

        ## Backup ##
        restic = {
          enable = true;
          endpointFile = config.sops.secrets."backup/restic/endpoint".path;
          credentialFile = config.sops.secrets."backup/restic/auth".path;
          encryptionFile = config.sops.secrets."backup/restic/encryption".path;
          dataDir = "/numina/apps";
        };

        ## Storage ##
        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
          dataDir = "/numina/apps/minio";
        };

        nfs4 = {
          enable = true;
          exports.app-backup = {
            path = "/numina/backup/apps";
            subnet = "172.19.82.0/24";
          };
        };

        timemachine = {
          enable = true;
          dataDir = "/numina/backup/timemachine";
        };
      };
    };
  };
}
