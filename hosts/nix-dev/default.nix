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
    modules = {
      desktop.enable = true;            # enable KDE desktop
      filesystems.zfs.enable = true;    # linux-on-zfs

      hardware = {
        nvidia.enable = true;           # llm support
      };

      services = {
        # : LLM
        ollama = {
          enable = true;
          models = ["deepseek-r1:8b"];
        };

        # : Apps
      };
    };
  };
}
