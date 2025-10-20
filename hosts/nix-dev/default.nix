{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  config = {
    # This is a must if "/home" is isolated from "/", for sops.
    fileSystems."/home".neededForBoot = true;

    modules = {
      filesystems.zfs.enable = true;
      # desktop.enable = true;
      # desktop.gaming.enable = true;

      hardware.nvidia.enable = true; # llm support

      services = {
        # : Networking
        dae.enable = true;
        dae.subscription = config.sops.secrets."networking/proxy/subscription".path;

        # : Monitoring
        smartd.enable = true;

        # : LLM
        ollama = {
          enable = true;
          acceleration = "cuda";
          models = ["deepseek-r1:8b"];
        };

        # : Apps
        roon.bridge.enable = true;
      };
    };
  };
}
