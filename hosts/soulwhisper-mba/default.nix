{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  # ref:https://daiderd.com/nix-darwin/manual/index.html
  config = {
    networking = {
      computerName = "soulwhisper-mba";
      hostName = hostname;
      localHostName = hostname;
    };

    # prefer unstable for implementing platform-specific fixes
    environment.systemPackages = with pkgs.unstable; [
      # cardforge, https://github.com/Card-Forge/forge/releases
      forge-mtg
    ];

    # test apps list
    homebrew = {
      taps = [
        {
          name = "brewforge/chinese";
          trusted = true;
        },
        {
          name = "pear-devs/pear";
          trusted = true;
        }
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
        "orbstack"
        "visual-studio-code"

        # :: web
        "google-chrome"

        # :: password management
        "1password"
        "1password-cli"

        # :: networking
        "brewforge/chinese/easytier-gui"
        "clash-verge-rev"
        "switchhosts" # replace adguard container
        "tailscale-app" # requires a kernel extension to work

        # :: storage
        "dropbox"
        "cyberduck" # replace transmit
        "transmission"

        # :: media
        "foobar2000"
        "iina"
        # "neteasemusic" # vendor HFS+ DMG unmountable via hdiutil on macOS 26.6; installed manually
        "pear-devs/pear/pear-desktop" # youtube-music replacement

        # :: productivity
        "acorn"
        "alfred" # powerpack still overshine Tahoe and raycast
        "discord"
        "ilok-license-manager"
        "obsidian"
        "stats"
        "squirrel-app"
        "telegram"
        "thunderbird"
        "ticktick"
        "vmware-fusion"
        "wechat"

        # :: utilities
        # "nikitabobko/tap/aerospace" # tilling, cant split
        # "jordanbaird-ice" # bartender replacement; check:https://github.com/jordanbaird/Ice/releases/download/0.11.13-dev.2/Ice.zip
        # "karabiner-elements" # not-used
        # "keyboard-maestro" # not-used
        "pixpin" # cleanshotx replacement
        "rectangle-pro" # preferred over swish

        # :: test
        # "betterdisplay"
        "little-snitch"
        "qlab"
        "wireshark-app"
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
  };
}
