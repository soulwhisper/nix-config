{
  pkgs,
  lib,
  config,
  hostname,
  ...
}:
let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  config = {
    networking = {
      hostName = hostname;
      hostId = "52a88b81";
      useDHCP = true;
      firewall.enable = true;
    };

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
          routes = [ "172.19.80.0/24" "172.19.82.0/24" ];
        };

        ## System ##
        adguard.enable = true;
        kms.enable = true;
        smartd.enable = true;
        nut.enable = true;

        # unifi is disabled due to https://github.com/NixOS/nixpkgs/issues/305015
        # unifi-controller.enable = true;

        ## Monitoring ##
        gatus.enable = true;
        exporters.node.enable = true;

        ## K8S:Talos ##
        talos.support.api.enable = true;
        talos.support.pxe.enable = true;

        ## Home-assistant ##
        hass = {
          dataDir = "/numina/apps/hass";
          core.enable = true;
          music.enable = true;
          sgcc.enable = true;
          sgcc.authFile = config.sops.secrets."hass/sgcc/auth".path;
        };

        ## APP ##
        glance.enable = true;
        homebox = {
          enable = true;
          dataDir = "/numina/apps/homebox";
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
          exports = "/numina/backup *(rw,async,insecure,no_root_squash,no_subtree_check)";
        };

        samba = {
          enable = true;
          avahi.TimeMachine.enable = true;
          settings = {
            Apps = {
              path = "/numina/apps";
              "read only" = "no";
            };
            Backup = {
              path = "/numina/backup";
              "read only" = "no";
            };
            Docs = {
              path = "/numina/docs";
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
