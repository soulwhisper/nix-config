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
      hostId = "52a88b83";
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
        chrony.enable = true;
        ddns.enable = true;

        ## Monitoring ##
        exporters.node.enable = true;
      };
    };

    # Use the systemd-boot EFI boot loader.
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
