{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # : Desktop applications
    # Ported from .archived/desktop/applications; pruned:
    #   dropbox / ticktick / vmware-workstation (dead upstreams),
    #   _1password-cli (provided by home-manager).
    environment.systemPackages = with pkgs; [
      # :: Base
      _1password-gui
      google-chrome
      obsidian
      thunderbird

      # :: Development
      ghostty
      vscode-fhs

      # :: Others
      discord
      vlc
      pear-desktop # formerly youtube-music
      zotero
    ];

    programs.wireshark.enable = true;
  };
}
