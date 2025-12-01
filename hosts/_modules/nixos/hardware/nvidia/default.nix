{
  config,
  lib,
  ...
}: let
  cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    enable = lib.mkEnableOption "nvidia";
    driverType = lib.mkOption {
      type = lib.types.enum ["desktop" "datacenter"];
      default = "desktop";
    };
  };

  # ref:https://wiki.nixos.org/wiki/NVIDIA

  # note:
  # nixpkgs.config.cudaSupport = true; would build all packages that offer cuda with CUDA support
  # Unfortunately, this would have some big drawbacks:
  # - CUDA stuff is not in cache.nixos.org (since unfree)
  # - would have to build everything from source, or from 'nix-community', take 2-3 hours
  # - CUDA stuff is not build by Hydra -> builds tend to fail more often since it's not tested
  # - packages like webkitgtk receive a lot of updates, and take a long time to build
  # -> CUDA support enabled for the whole system is neither practical nor necessary
  # -> we should enable CUDA support for specific packages only
  # example: pkgs.cuda-app.override { cudaSupport = true; };

  ## desktop-version: https://github.com/NixOS/nixpkgs/blob/nixos-25.11/pkgs/os-specific/linux/nvidia-x11/default.nix#L58
  ## datacenter-version: https://github.com/NixOS/nixpkgs/blob/nixos-25.11/pkgs/os-specific/linux/nvidia-x11/default.nix#L94
  config = lib.mkIf cfg.enable {
    # LACT for Nvidia GPU
    services.lact.enable = true;

    # if desktop
    services.xserver.videoDrivers = lib.mkIf (cfg.driverType == "desktop") ["nvidia"];

    boot.kernelParams = [
      # Since NVIDIA does not load kernel mode setting by default,
      # enabling it is required to make Wayland compositors function properly.
      "nvidia-drm.fbdev=1"
    ];

    hardware = {
      graphics = {
        enable = true;
        # needed by nvidia-docker
        enable32Bit = true;
      };
      nvidia-container-toolkit.enable = true;
      nvidia = {
        # if datacenter
        datacenter.enable = lib.mkIf (cfg.driverType == "datacenter") true;

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
    };
  };
}
