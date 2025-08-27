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
      desktop.enable = true;

      hardware = {
        nvidia.enable = true; # llm support
      };

      services = {
        # : System
        smartd.enable = true;

        # : LLM
        ollama = {
          enable = true;
          models = ["deepseek-r1:8b"];
        };
        sillytavern.enable = true;

        # : Apps
      };
    };
  };
}
