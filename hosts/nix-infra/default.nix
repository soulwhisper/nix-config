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
      hostId = "52a88b82";
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

    systemd.tmpfiles.rules = [
      "d /opt/backup 0644 root root - -"
      "d /opt/timemachine 0644 root root - -"
      "d /home/appuser 0644 appuser appuser - -"
      "d /home/appuser/apps 0644 appuser appuser - -"
    ];

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      chsh -s /run/current-system/sw/bin/fish soulwhisper
    '';

    modules = {
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

        vpn = {
          easytier = {
            enable = true;
            authFile = config.sops.secrets."networking/easytier/auth".path;
            routes = [ "10.0.0.0/24" "10.10.0.0/24" ];
          };
          tailscale = {
            enable = true;
            authFile = config.sops.secrets."networking/tailscale/auth".path;
          };
        };

        ## System ##
        adguard.enable = true;
        chrony.enable = true;
        ddns.enable = true;
        kms.enable = true;

        ## Monitoring ##
        exporters.node.enable = true;

        ## K8S:Talos ##
        talos.support.api.enable = true;

        ## Backup ##
        backup = {
          restic = {
            enable = true;
            endpointFile = config.sops.secrets."backup/restic/endpoint".path;
            credentialFile = config.sops.secrets."backup/restic/auth".path;
            encryptionFile = config.sops.secrets."backup/restic/encryption".path;
            dataDir = "/home/appuser/apps";
          };
        };

        ## Storage ##
        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
          dataDir = "/home/appuser/apps/minio";
        };

        nfs = {
          enable = true;
          exports = "/opt/backup *(rw,async,insecure,no_root_squash,no_subtree_check)";
        };

        samba = {
          enable = true;
          avahi.TimeMachine.enable = true;
          settings = {
            Backup = {
              path = "/opt/backup";
              "read only" = "no";
            };
            Software = {
              path = "/home/appuser/apps";
              "read only" = "no";
            };
            TimeMachine = {
              path = "/opt/timemachine";
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