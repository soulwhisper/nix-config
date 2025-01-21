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

    # stable apps list
    taps = [
    ];
    brews = [
    ];
    casks = [
      "1password"
      "clash-verge-rev"
      "dropbox"
      "gifox"
      "google-chrome"
      "iterm2"
      "jordanbaird-ice"
      "karabiner-elements"
      "keyboard-maestro"
      "notunes"
      "obsidian"
      "raycast"
      "shottr"
    ];
    masApps = {
      "Caffeinated" = 1362171212;
      "Keka" = 470158793;
      "Numbers" = 409203825;
      "Pages" = 409201541;
    };
  };
}
