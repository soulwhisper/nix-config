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

    # stable apps list
    taps = [
      "th-ch/youtube-music"
    ];
    brews = [
    ];
    casks = [
      "1password"
      "1password-cli"
      "clash-verge-rev"
      "dropbox"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "google-chrome"
      "jordanbaird-ice"
      "karabiner-elements"
      "keyboard-maestro"
      "obsidian"
      "raycast"
      "youtube-music"
      "vmware-fusion"
    ];
    masApps = {
      "Caffeinated" = 1362171212;
      "Keka" = 470158793;
      "Numbers" = 409203825;
      "Pages" = 409201541;
    };
  };
}
