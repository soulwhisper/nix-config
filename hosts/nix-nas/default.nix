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

    users.mutableUsers = false;
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

    # additional users and groups
    users.users = {
      appuser = {
        group = "appuser";
        uid = 1001;
        isSystemUser = true;
      };
    };
    users.groups = {
      appuser.gid = 1001;
    };

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
        openssh.enable = true;

        dae = {
          enable = true;
          subscriptionFile = config.sops.secrets."networking/dae/subscription".path;
        };

        caddy = {
          enable = true;
          CloudflareToken = config.sops.secrets."networking/cloudflare/auth".path;
        };

        ## Optional ##
        adguard.enable = true;
        chrony.enable = true;
        ddns.enable = true;
        talos-api.enable = true;
        gatus.enable = true;
        glance.enable = true;
        kms.enable = true;
        node-exporter.enable = true;

        home-assistant = {
          enable = true;
          configDir = "/numina/apps/home-assistant";
        };
        hass-sgcc = {
          enable = true;
          dataDir = "/numina/apps/hass-sgcc";
          authFile = config.sops.secrets."hass.sgcc.auth".path;
        };
        music-assistant = {
          enable = true;
          dataDir = "/numina/apps/music-assistant";
        };
        homebox = {
          enable = true;
          dataDir = "/numina/apps/homebox";
        };
        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
          dataDir = "/numina/apps/minio";
        };

        ## NAS ##
        # smartd.enable = true;
        # smartctl-exporter.enable = true;
        ups.enable = true;

        nfs = {
          enable = true;
          exports = "/numina/backup *(rw,async,insecure,no_root_squash,no_subtree_check)";
        };

        samba = {
          enable = true;
          avahi.TimeMachine.enable = true;
          settings = {
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
            Software = {
              path = "/numina/apps";
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
