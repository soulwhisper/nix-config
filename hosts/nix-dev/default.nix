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
        ## LLM ##
        ollama = {
          enable = true;
          models = ["deepseek-r1:8b"];
        };

        ## Apps ##
        lobechat = {
          enable = true;
          authFile = config.sops.secrets."apps/lobechat/auth".path;
        };
      };
    };
  };
}
