{config, ...}: {
  imports = [
    # : folder
    ./hardware
    ./filesystems
    ./secrets
    ./services

    # : files
    ./desktop.nix
    ./nix.nix
    ./sops.nix
    ./users.nix
  ];

  config = {
    # : increase open file limit for sudoers
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

    # : disable unnecessary services
    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;

    # : sysctl
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 7500000;
      "net.core.wmem_max" = 7500000;
      "net.ipv4.ip_local_port_range" = "60000 65000";
    };

    # : systemd-boot EFI boot loader.
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # : default services for all host
    modules.services = {
      chrony.enable = true;
      easytier.enable = true;
      easytier.authFile = config.sops.secrets."networking/easytier/auth".path;
      mihomo.enable = true;
      mihomo.subscriptionFile = config.sops.secrets."networking/proxy/subscription".path;
      monitoring.enable = true;
      openssh.enable = true;
    };

    system.stateVersion = "25.05";
  };
}
