{
  lib,
  pkgs,
  config,
  ...
}: {
  # desktop-version: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/os-specific/linux/nvidia-x11/default.nix#L58
  # datacenter-version: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/os-specific/linux/nvidia-x11/default.nix#L94
  services.xserver.videoDrivers = ["nvidia"]; # if desktop
  # hardware.nvidia.datacenter.enable = true; # if datacenter

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # This ensures all GPUs stay awake even during headless mode
    nvidiaPersistenced = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.stable; # if datacenter then `dc`
  };
}
