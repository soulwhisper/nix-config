_: {
  security.pam.services.sudo_local.reattach = true;
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    CustomSystemPreferences = {
      # Enable Launchpad in macOS 26 Tahoe
      "/Library/Preferences/FeatureFlags/Domain/SpotlightUI" = {
        SpotlightPlus.Enabled = false;
      };
    };

    CustomUserPreferences = {
      # Limit Ad Tracking
      "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
      # Prevent .DS_store file creation
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # Disable wallpaper tinting
      "NSGlobalDomain".AppleReduceDesktopTinting = true;
    };

    NSGlobalDomain = {
      # Disable automatically switch between light and dark mode.
      AppleInterfaceStyleSwitchesAutomatically = false;
      # Whether to show all file extensions in Finder
      AppleShowAllExtensions = true;
      # Disable automatic capitalization
      NSAutomaticCapitalizationEnabled = false;
      # Disable smart dash substitution
      NSAutomaticDashSubstitutionEnabled = false;
      # Disable smart period substitution
      NSAutomaticPeriodSubstitutionEnabled = false;
      # Disable smart quote substitution
      NSAutomaticQuoteSubstitutionEnabled = false;
      # Disable automatic spelling correction
      NSAutomaticSpellingCorrectionEnabled = false;
      # Sets the size of the finder sidebar icons
      NSTableViewDefaultSizeMode = 1;
      # Configures the trackpad tap behavior.  Mode 1 enables tap to click.
      "com.apple.mouse.tapBehavior" = 1;
      # Enable trackpad secondary click.
      "com.apple.trackpad.enableSecondaryClick" = true;
      # Disable autohide the menu bar.
      _HIHideMenuBar = false;
    };

    WindowManager = {
      # Only in Stage Manager, click wallpaper to reveal desktop
      EnableStandardClickToShowDesktop = false;
    };

    dock = {
      # Show appswitcher on all displays
      appswitcher-all-displays = false;
      # Automatically show and hide the dock
      autohide = true;
      # Disable automatically rearrange spaces, needed by window tiling tools
      mru-spaces = false;
      # Position of the dock on screen.
      orientation = "left";
      # Show recent applications in the dock.
      show-recents = false;
    };

    finder = {
      # Show all extensions
      AppleShowAllExtensions = true;
      # Show icons on desktop
      CreateDesktop = false;
      # Disable warning when changing file extension
      FXEnableExtensionChangeWarning = false;
      # Default Finder window set to list view
      FXPreferredViewStyle = "Nlsv";
      # Show status bar
      ShowStatusBar = true;
      # Show path bar
      ShowPathbar = true;
    };
  };
}
