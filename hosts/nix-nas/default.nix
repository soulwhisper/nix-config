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
        chrony = {
          enable = true;
          servers = [
            "time.cloudflare.com"
            "time.apple.com"
          ];
        };

        nginx = {
          enableAcme = true;
          acmeCloudflareAuthFile = config.sops.secrets."networking/cloudflare/auth".path;
        };

        minio = {
          enable = true;
          package = pkgs.unstable.minio;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
          dataDir = "/numina/apps/minio";
          enableReverseProxy = true;
          minioConsoleURL = "minio.noirprime.com";
          minioS3URL = "s3.noirprime.com";
        };

        nfs.enable = true;

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
              path = "/numina/software";
              "read only" = "no";
            };
            TimeMachineBackup = {
              path = "/numina/backup/timemachine";
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
