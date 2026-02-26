_: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # Don't update during rebuild
      cleanup = "zap"; # Uninstall all programs not declared
      upgrade = true;
    };
    global = {
      brewfile = true; # Run brew bundle from anywhere
      lockfiles = false; # Don't save lockfile (since running from anywhere)
    };

    # : stable apps list
    # * fix damaged error: `/usr/bin/xattr -cr /Applications/appname.app`
    taps = [
      "pear-devs/pear"
    ];
    brews = [
      "mas"
    ];
    casks = [
      # :: fonts
      "font-lxgw-neoxihei"
      "font-jetbrains-mono-nerd-font"

      # :: password management
      "1password"
      "1password-cli"

      # :: networking
      "brewforge/chinese/easytier"
      "clash-verge-rev"
      "switchhosts" # replace adguard container

      # :: storage
      "dropbox"
      "cyberduck" # replace transmit
      "transmission"

      # :: development
      "cursor"
      "ghostty"
      "opencode-desktop"
      "orbstack"
      "visual-studio-code"

      # :: web
      "google-chrome"

      # :: media
      "foobar2000"
      "iina"
      "neteasemusic"
      "pear-desktop" # youtube-music replacement

      # :: productivity
      "acorn"
      "alfred" # powerpack still overshine Tahoe and raycast
      "discord"
      "ilok-license-manager"
      "obsidian"
      "stats"
      "squirrel-app"
      "telegram"
      "tencent-meeting"
      "thunderbird"
      "ticktick"
      "vmware-fusion"
      "wechat"
      "zotero"

      # :: utilities
      # "nikitabobko/tap/aerospace" # tilling, cant split
      "jordanbaird-ice" # bartender replacement
      # "vanilla" # ice replacement
      # "karabiner-elements" # not-used
      # "keyboard-maestro" # not-used
      "pixpin" # cleanshotx replacement
      "rectangle-pro" # preferred over swish
    ];
    masApps = {
      "Caffeinated" = 1362171212;
      "DevHub" = 6476452351;
      "iCost" = 1484262528;
      "Keka" = 470158793;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "ReadKit" = 1615798039;
      "Keynote" = 409183694;
      "Windows App" = 1295203466;
    };
  };
}
