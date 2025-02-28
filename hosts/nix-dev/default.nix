{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  config = {
    modules = {
      desktop.enable = true; # enable KDE desktop

      hardware = {
        nvidia.enable = true; # llm support
      };

      services = {
        ## Apps ##
        llm.enable = true;
      };
    };
  };
}
