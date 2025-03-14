{config, ...}: {
  imports = [
    ## folder ##
    ./hardware
    ./filesystems
    ./secrets
    ./services

    ## files ##
    ./desktop.nix
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

    # Use the systemd-boot EFI boot loader.
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # default services for all host
    modules.services = {
      auto-rebuild.enable = true;
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
