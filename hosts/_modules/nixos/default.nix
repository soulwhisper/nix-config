{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # : folder
    ./filesystems
    ./hardware
    ./secrets
    ./services

    # : files
    ./nix.nix
    ./users.nix
  ];

  config = {
    # : linux_x86_64 only packages
    environment.systemPackages = with pkgs; [
      freefilesync
    ];

    # : networking
    systemd.network.enable = true;
    networking = {
      firewall.enable = true;
      nftables.enable = true;
      useNetworkd = false;
      useDHCP = false;
    };

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
      systemd-boot.configurationLimit = lib.mkDefault 10;
      efi.canTouchEfiVariables = true;
    };

    # : default services for all host
    modules.services = {
      chrony.enable = true;
      easytier.enable = true;
      easytier.authFile = config.sops.secrets."networking/easytier/auth".path;
      mihomo.enable = true;
      mihomo.subscription = config.sops.secrets."networking/proxy/subscription".path;
      monitoring.enable = true;
      openssh.enable = true;
    };

    system.stateVersion = "25.11";
  };
}
