{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop;
in {
  options.modules.desktop = {
    enable = lib.mkEnableOption "desktop";
  };

  config = lib.mkIf cfg.enable {
    # KDE Plasma 6, ref:https://wiki.nixos.org/wiki/KDE
    services.xserver.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      settings.General.DisplayServer = "wayland";
    };
    services.desktopManager.plasma6.enable = true;

    # Desktop Software for x86_64
    environment.systemPackages = with pkgs.unstable; [
      # : Base
      _1password-cli
      _1password-gui
      clash-verge-rev
      cyberduck
      dropbox
      google-chrome
      obsidian
      thunderbird
      ticktick

      # : Development
      code-cursor-fhs
      ghostty
      nerd-fonts.jetbrains-mono
      vscode-fhs
      vmware-workstation

      # : Others
      discord
      vlc
      youtube-music
    ];
  };
}
