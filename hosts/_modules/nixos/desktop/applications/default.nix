{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop;
in {
  options.modules.desktop = {
    enable = lib.mkEnableOption "desktop";
    manager = lib.mkOption {
      default = "kde";
      type = lib.types.enum [
        "kde"
        "hyperland"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # : Desktop Software for x86_64
    environment.systemPackages = with pkgs.unstable; [
      # :: Base
      _1password-cli
      _1password-gui
      clash-verge-rev
      cyberduck
      dropbox
      google-chrome
      obsidian
      thunderbird
      ticktick

      # :: Development
      code-cursor-fhs
      ghostty
      nerd-fonts.jetbrains-mono
      vscode-fhs
      vmware-workstation

      # :: Others
      discord
      vlc
      youtube-music
    ];

    # : Laptop Support
    services.thermald.enable = true;
    services.power-profiles-daemon.enable = lib.mkForce false; # override kde, conflict with auto-cpufreq
    services.auto-cpufreq.enable = true; # replace tlp
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };
}
