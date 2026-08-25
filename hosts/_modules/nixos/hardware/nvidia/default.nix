{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.hardware.nvidia;
in
{
  options.modules.hardware.nvidia = {
    enable = lib.mkEnableOption "nvidia";

    # Turing or newer: open kernel modules recommended (RTX, GTX 16xx).
    # Upstream asserts an explicit choice on driver >= 560.
    openKernelModules = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use the open source NVIDIA kernel modules (Turing+).";
    };

    prime = {
      offload.enable = lib.mkEnableOption "PRIME render offload (hybrid notebook)";
      sync.enable = lib.mkEnableOption "PRIME sync (output driven by NVIDIA GPU)";
      intelBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Bus ID of the Intel iGPU, e.g. \"PCI:0:2:0\".";
      };
      amdgpuBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Bus ID of the AMD iGPU, e.g. \"PCI:5:0:0\".";
      };
      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Bus ID of the NVIDIA dGPU, e.g. \"PCI:1:0:0\".";
      };
    };

    dynamicBoost = lib.mkEnableOption "nvidia-powerd dynamic CPU/GPU power balancing (supported laptops)";

    # Local compute is planned to run in containers; keep the toolkit even on
    # gaming hosts so CUDA containers work out of the box.
    containerToolkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable nvidia-container-toolkit for CUDA containers.";
    };
  };

  # ref:https://wiki.nixos.org/wiki/NVIDIA

  # note:
  # nixpkgs.config.cudaSupport = true; would build all packages that offer cuda with CUDA support
  # Unfortunately, this would have some big drawbacks:
  # - CUDA stuff is not in cache.nixos.org (since unfree)
  # - would have to build everything from source, or from 'nix-community', take 2-3 hours
  # -> enable CUDA support for specific packages only
  # example: pkgs.cuda-app.override { cudaSupport = true; };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.prime.offload.enable && cfg.prime.sync.enable);
        message = "modules.hardware.nvidia.prime: offload and sync are mutually exclusive.";
      }
      {
        assertion =
          !(cfg.prime.offload.enable || cfg.prime.sync.enable)
          || (cfg.prime.nvidiaBusId != "" && (cfg.prime.intelBusId != "" || cfg.prime.amdgpuBusId != ""));
        message = "modules.hardware.nvidia.prime: nvidiaBusId and one of intelBusId/amdgpuBusId are required when PRIME is enabled.";
      }
    ];

    services.lact.enable = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    boot.kernelParams = [
      # Since NVIDIA does not load kernel mode setting by default,
      # enabling it is required to make Wayland compositors function properly.
      "nvidia-drm.fbdev=1"
    ];

    hardware = {
      graphics.enable = true;

      nvidia-container-toolkit.enable = cfg.containerToolkit;

      nvidia = {
        open = cfg.openKernelModules;

        modesetting.enable = true;

        # RTD3 power management: only meaningful (and safe) for hybrid
        # offload laptops; on desktops it can break suspend/resume.
        powerManagement.enable = lib.mkDefault cfg.prime.offload.enable;
        powerManagement.finegrained = lib.mkDefault cfg.prime.offload.enable;

        nvidiaSettings = true;
        dynamicBoost.enable = cfg.dynamicBoost;

        prime = lib.mkMerge [
          (lib.mkIf cfg.prime.offload.enable {
            offload.enable = true;
            offload.enableOffloadCmd = true;
          })
          (lib.mkIf cfg.prime.sync.enable {
            sync.enable = true;
          })
          (lib.mkIf (cfg.prime.intelBusId != "") {
            intelBusId = cfg.prime.intelBusId;
          })
          (lib.mkIf (cfg.prime.amdgpuBusId != "") {
            amdgpuBusId = cfg.prime.amdgpuBusId;
          })
          (lib.mkIf (cfg.prime.nvidiaBusId != "") {
            nvidiaBusId = cfg.prime.nvidiaBusId;
          })
        ];

        # Driver branch/package selection: upstream defaults to `stable`;
        # override `hardware.nvidia.package` at host level if ever needed.
      };
    };
  };
}
