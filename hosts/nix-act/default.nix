{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  # spec: N100 4C32G, 1TB NVMe/SATA; bare metal agent computer.

  config = {
    # This is a must if "/home" is isolated from "/", for sops.
    fileSystems."/home".neededForBoot = true;

    modules = {
      desktop = {
        enable = true;
        environment = "niri";
      };

      filesystems.xfs.enable = true;
      services = {
        caddy.enable = true;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;

        # : Networking
        tailscale.enable = false;

        # : Monitoring
        scrutiny.enable = false;
        smartd.enable = false;
        nut.enable = false;

        # : Main
        dsh.enable = true;
      };
    };

    # : N100 / Alder Lake-N
    hardware = {
      cpu.intel.updateMicrocode = true;
      enableRedistributableFirmware = true;
      graphics.extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        libva-utils
      ];
    };
    services.thermald.enable = true;

    # : desktop/base switches to NetworkManager; keep the existing
    # systemd-networkd static configuration for this fixed wired host.
    networking.networkmanager.enable = lib.mkForce false;
    networking.useNetworkd = lib.mkForce true;
    systemd.network.enable = lib.mkForce true;

    # : Caddy loads Cloudflare credentials from authFile and the dsh
    # basic-auth hash from a separate sops env file.
    systemd.services.caddy.serviceConfig.EnvironmentFile = lib.mkAfter [
      config.sops.secrets."networking/dsh/auth".path
    ];
  };
}
