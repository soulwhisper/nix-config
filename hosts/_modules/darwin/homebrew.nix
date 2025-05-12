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
      "1password-cli"
      "clash-verge-rev"
      "dropbox"
      "ghostty"
      "google-chrome"
      "jordanbaird-ice"
      "karabiner-elements"
      "keyboard-maestro"
      "obsidian"
      "raycast"
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
