{
  pkgs,
  lib,
  config,
  hostname,
  ...
}: let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  imports = [
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  config = {
    networking = {
      hostName = hostname;
      firewall.enable = true;
      nftables.enable = true;
      interfaces = {
        enp6s18.ipv4.addresses = [{
          address = "10.0.0.10";   # LAN, vmbr2
          prefixLength = 24;
        }];
        enp6s18.ipv4.routes = [{
          address = "10.0.0.0";
          prefixLength = 24;
          via = "10.0.0.1";
        }];
        enp6s19.ipv4.addresses = [{
          address = "10.20.0.10";  # unifi-ap, vmbr0
          prefixLength = 24;
        }];
      };
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

    systemd.tmpfiles.rules = [
      "d /opt/backup 0644 root root - -"
      "d /opt/media 0644 root root - -"
      "d /opt/timemachine 0644 root root - -"
    ];

    modules = {
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
          routes = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];
        };

        ## System ##
        adguard.enable = true;

        ## K8S:Talos ##
        talos.api.enable = true;

        ## Apps ##
        glance.enable = true;
        #  homebox.enable = true;
        home-assistant.enable = true;
        home-assistant.sgcc.authFile = config.sops.secrets."apps/hass-sgcc/auth".path;
        kms.enable = true;
        unifi-controller.enable = true;
        #  zotregistry.enable = true;

        ## Backup ##
        #  restic = {
        #    enable = true;
        #    endpointFile = config.sops.secrets."backup/restic/endpoint".path;
        #    credentialFile = config.sops.secrets."backup/restic/auth".path;
        #    encryptionFile = config.sops.secrets."backup/restic/encryption".path;
        #    dataDir = "/opt/apps";
        #  };

        ## Storage ##
        minio = {
          enable = true;
          rootCredentialsFile = config.sops.secrets."storage/minio/root-credentials".path;
        };

        #  nfs = {
        #    enable = true;
        #    exports = ''
        #      /opt/backup *(rw,async,insecure,no_root_squash,no_subtree_check)
        #      /opt/media *(rw,async,insecure,no_root_squash,no_subtree_check)
        #    '';
        #  };

        samba = {
          enable = true;
          avahi.TimeMachine.enable = true;
          settings = {
            Backup = {
              path = "/opt/backup";
              "read only" = "no";
            };
            #    Media = {
            #      path = "/numina/media";
            #      "read only" = "no";
            #    };
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
