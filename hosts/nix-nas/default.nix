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
      firewall.enable = false;
      networkmanager.enable = true;
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
          "networkmanager"
        ]
        ++ ifGroupsExist [
          "network"
          "samba-users"
        ];
    };
    users.groups.soulwhisper = {
      gid = 1000;
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
        adguard.enable = true;
        chrony.enable = true;
        dae = {
          enable = true;
          subscription = config.sops.secrets."networking/dae/subscription".path;
        };

        glance = {
          enable = true;
          glanceURL = "lab.noirprime.com";
        };
        home-assistant = {
          enable = true;
          configDir = "/numina/apps/hass";
        };

        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
          dataDir = "/numina/apps/minio";
          enableReverseProxy = true;
          minioConsoleURL = "minio.noirprime.com";
          minioS3URL = "s3.noirprime.com";
        };

        nfs = {
          enable = true;
          exports = "/numina/backup *(rw,async,insecure,no_root_squash,no_subtree_check)";
        };

        nginx = {
          enableAcme = true;
          acmeCloudflareAuthFile = config.sops.secrets."networking/cloudflare/auth".path;
        };

        node-exporter.enable = true;
        openssh.enable = true;

        samba = {
          enable = true;
          shares = {
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

        smartd.enable = true;
        smartctl-exporter.enable = true;
      };

      users = {
        additionalUsers = {
          manyie = {
            isNormalUser = true;
            extraGroups = ifGroupsExist [
              "samba-users"
            ];
          };
        };
        groups = {
          external-services = {
            gid = 65542;
          };
          admins = {
            gid = 991;
            members = [
              "soulwhisper"
            ];
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
