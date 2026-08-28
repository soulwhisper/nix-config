# Core homebrew wiring shared by every darwin host. Desktop apps live in
# hosts/soulwhisper-mba; headless hosts (soulwhisper-studio) declare only
# what they serve with.
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
    ];
    casks = [
    ];
    masApps = {
    };
  };
}
