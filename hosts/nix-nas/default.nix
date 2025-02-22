{
  pkgs,
  lib,
  config,
  ...
}: let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  config = {
    users.users.soulwhisper = {
      uid = 1000;
      name = "soulwhisper";
      home = "/home/soulwhisper";
      group = "soulwhisper";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = lib.strings.splitString "\n" (builtins.readFile ../../homes/soulwhisper/config/ssh/ssh.pub);
      hashedPasswordFile = config.sops.secrets."users/soulwhisper/password".path;
      isNormalUser = true;
      extraGroups =
        [
          "wheel"
          "users"
        ]
        ++ ifGroupsExist [
          "network"
          "samba-users"
        ];
    };
    users.groups.soulwhisper.gid = 1000;

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      chsh -s /run/current-system/sw/bin/fish soulwhisper
    '';

    modules = {
      filesystems.zfs = {
        enable = true;
        mountPoolsAtBoot = [
          "numina"
        ];
      };

      services = {
        ## Mandatory ##
        chrony.enable = true;
        openssh.enable = true;
        monitoring.enable = true;

        dae = {
          enable = true;
          subscriptionFile = config.sops.secrets."networking/dae/subscription".path;
        };

        caddy = {
          enable = true;
          CloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };

        easytier = {
          enable = true;
          authFile = config.sops.secrets."networking/easytier/auth".path;
          proxy_networks = [];
        };

        ## System ##
        adguard.enable = true;
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

    # Use the systemd-boot EFI boot loader.
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
