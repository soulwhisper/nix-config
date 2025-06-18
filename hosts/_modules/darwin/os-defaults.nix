_: {
  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    defaults = {
      # : comment value is default now
      NSGlobalDomain = {
        # Whether to automatically switch between light and dark mode.
        # AppleInterfaceStyleSwitchesAutomatically = false;
        # Whether to show all file extensions in Finder
        AppleShowAllExtensions = true;
        # Whether to enable automatic capitalization.
        NSAutomaticCapitalizationEnabled = false;
        # Whether to enable smart dash substitution.
        NSAutomaticDashSubstitutionEnabled = false;
        # Whether to enable smart period substitution.
        NSAutomaticPeriodSubstitutionEnabled = false;
        # Whether to enable smart quote substitution.
        NSAutomaticQuoteSubstitutionEnabled = false;
        # Whether to enable automatic spelling correction.
        NSAutomaticSpellingCorrectionEnabled = false;
        # Sets the size of the finder sidebar icons.
        NSTableViewDefaultSizeMode = 1;
        # Configures the trackpad tap behavior.  Mode 1 enables tap to click.
        "com.apple.mouse.tapBehavior" = 1;
        # Whether to enable trackpad secondary click.
        # "com.apple.trackpad.enableSecondaryClick" = true;
        # Whether to autohide the menu bar.
        # _HIHideMenuBar = false;
      };

      # turn off wallpaper tinting

      dock = {
        # Show appswitcher on all displays
        # appswitcher-all-displays = false;
        # Automatically show and hide the dock
        autohide = true;
        # Position of the dock on screen.
        orientation = "left";
        # Show recent applications in the dock.
        show-recents = false;
      };

      finder = {
        # Show status bar
        ShowStatusBar = true;
        # Default Finder window set to list view
        FXPreferredViewStyle = "Nlsv";
        # Show path bar
        ShowPathbar = true;
        # Show all extensions
        AppleShowAllExtensions = true;
        # Show icons on desktop
        CreateDesktop = false;
        # Disable warning when changing file extension
        FXEnableExtensionChangeWarning = false;
      };
    };
  };
}
