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
        smartd.enable = true;
        nut.enable = true;

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
        lobechat = {
          enable = true;
          dataDir = "/numina/apps/lobechat";
          authFile = config.sops.secrets."apps/lobechat/auth".path;
        };
        netbox = {
          enable = true;
          dataDir = "/numina/apps/netbox";
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
        postgresql.dataDir = "/numnia/apps/postgres";

        ## Storage ##
        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
          dataDir = "/numina/apps/minio";
        };

        nfs4 = {
          enable = true;
          exports = ''
            /numina/backup/apps 172.19.82.0/24(rw,async,anonuid=1001,anongid=1001)
          '';
        };

        timemachine = {
          enable = true;
          dataDir = "/numina/backup/timemachine";
        };
      };
    };
  };
}
