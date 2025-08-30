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
    environment.systemPackages = with pkgs; [
      # :: Base
      _1password-cli
      _1password-gui
      dropbox
      google-chrome
      obsidian
      thunderbird
      ticktick

      # :: Development
      code-cursor-fhs
      ghostty
      vscode-fhs
      vmware-workstation

      # :: Fonts
      lxgw-neoxihei
      nerd-fonts.jetbrains-mono

      # :: Others
      discord
      vlc
      youtube-music
    ];

    programs.clash-verge = {
      enable = true;
      autoStart = true;
    };
    programs.wireshark.enable = true;
  };
}
