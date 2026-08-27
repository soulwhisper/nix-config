_: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # Don't update during rebuild
      cleanup = "zap"; # Uninstall all programs not declared
      upgrade = true;
    };

    # : stable apps list
    # * fix damaged error: `/usr/bin/xattr -cr /Applications/appname.app`
    taps = [
    ];
    brews = [
      "mas"
    ];
    casks = [
      # :: fonts
      "font-lxgw-neoxihei"
      "font-jetbrains-mono-nerd-font"

      # :: development
      "ghostty"
      "visual-studio-code"

      # :: web
      "google-chrome"
    ];
    masApps = {
      "Caffeinated" = 1362171212;
    };
  };
}
