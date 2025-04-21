{config, ...}: {
  imports = [
    ## folder ##
    ./hardware
    ./filesystems
    ./secrets
    ./services

    ## files ##
    ./desktop.nix
    ./disk-config.nix
    ./nix.nix
    ./sops.nix
    ./users.nix
  ];

  config = {
    # Increase open file limit for sudoers
    security.pam.loginLimits = [
      {
        domain = "@wheel";
        item = "nofile";
        type = "soft";
        value = "524288";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "1048576";
      }
    ];

    # disable unnecessary services
    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;

    # Use the systemd-boot EFI boot loader.
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Use polymouth to prettify boot
    boot.plymouth.enable = true;

    # linux-on-zfs, using disko.nix
    modules.filesystems.zfs.enable = true;

    # default services for all host
    modules.services = {
      chrony.enable = true;
      dae.enable = true;
      dae.subscriptionFile = config.sops.secrets."networking/dae/subscription".path;
      easytier.enable = true;
      easytier.authFile = config.sops.secrets."networking/easytier/auth".path;
      monitoring.enable = true;
      openssh.enable = true;
    };

    system.stateVersion = "24.11";
  };
}
