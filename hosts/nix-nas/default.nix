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
          CloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };

        ## System ##
        smartd.enable = true;
        nut.enable = true;

        ## K8S:Talos ##
        talos.api.enable = true;

        ## Apps ##
        glance.enable = true;
        kms.enable = true;
        home-assistant = {
          enable = true;
          dataDir = "/numina/apps/home-assistant";
          sgcc.authFile = config.sops.secrets."apps/hass-sgcc/auth".path;
        };
        netbox = {
          enable = true;
          dataDir = "/numina/backup/netbox";
        };
        unifi-controller = {
          enable = true;
          dataDir = "/numina/apps/unifi-controller";
        };
        zotregistry = {
          enable = true;
          dataDir = "/numina/apps/zot";
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

        nfs = {
          enable = true;
          exports = ''
            /numina/backup *(rw,async,insecure,no_root_squash,no_subtree_check)
            /numina/media *(rw,async,insecure,no_root_squash,no_subtree_check)
          '';
        };

        # nix-nas only
        samba = {
          enable = true;
          avahi.TimeMachine.enable = true;
          settings = {
            Backup = {
              path = "/numina/backup";
              "read only" = "no";
            };
            Media = {
              path = "/numina/media";
              "read only" = "no";
            };
            TimeMachine = {
              path = "/numina/timemachine";
              "read only" = "no";
              "fruit:aapl" = "yes";
              "fruit:time machine" = "yes";
            };
          };
        };
      };
    };
  };
}
