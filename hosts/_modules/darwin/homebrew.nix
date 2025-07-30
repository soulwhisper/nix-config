_: {
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true; # fix signature verification failed error
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
      "th-ch/youtube-music"
    ];
    brews = [
    ];
    casks = [
      # :: password management
      "1password"
      "1password-cli"

      # :: networking
      "brewforge/chinese/easytier"
      "clash-verge-rev"
      "switchhosts" # replace adguard container

      # :: storage
      "dropbox"
      "transmit"

      # :: development
      "cursor"
      "orbstack"
      "visual-studio-code"

      # :: web
      "google-chrome"

      # :: media
      "iina"
      "youtube-music"

      # :: productivity
      "alfred" # powerpack still overshine Tahoe and raycast
      "obsidian"
      "thunderbird"
      "ticktick"
      "vmware-fusion"

      # :: utilities
      "jordanbaird-ice" # bartender replacement
      "karabiner-elements"
      "keyboard-maestro"
      "pixpin" # cleanshotx replacement
      "swish"
    ];
    masApps = {
      "Caffeinated" = 1362171212;
      "Keka" = 470158793;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Keynote" = 409183694;
    };
  };
}
