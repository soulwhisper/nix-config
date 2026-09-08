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

    environment.systemPackages = with pkgs.unstable; [
      # cardforge, https://github.com/Card-Forge/forge/releases
      forge-mtg
    ];

    # apps list
    homebrew = {
      taps = [
        {
          name = "brewforge/chinese";
          trusted = true;
        }
        {
          name = "FelixKratz/formulae";
          trusted = true;
        }
        {
          name = "nikitabobko/tap";
          trusted = true;
        }
        {
          name = "pear-devs/pear";
          trusted = true;
        }
      ];
      brews = [
        "mas"
        "mole" # mo clean --dry-run / mo analyze / mo purge
        "gopeed" # replace transmission
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
        "little-snitch"
        "switchhosts" # replace adguard container
        "tailscale-app" # requires a kernel extension to work
        "wireshark-app"

        # :: storage
        "dropbox"
        "cyberduck" # replace transmit

        # :: media
        "foobar2000"
        "iina"
        "pear-devs/pear/pear-desktop" # replace youtube-music

        # :: productivity
        "acorn"
        "alfred" # powerpack replace tahoe and raycast
        "cherry-studio"
        "discord"
        "ilok-license-manager"
        "obsidian"
        "qlab"
        "stats"
        "squirrel-app"
        "telegram"
        "thunderbird"
        "ticktick"
        "vmware-fusion"
        "wechat"

        # :: utilities
        # https://github.com/jordanbaird/Ice/releases/download/0.11.13-dev.2/Ice.zip
        "FelixKratz/formulae/borders"
        "nikitabobko/tap/aerospace" # replace rectangle-pro and swish
        # "betterdisplay" # not-used
        # "karabiner-elements" # not-used
        # "keyboard-maestro" # not-used
        "pixpin" # replace cleanshotx

        # :: test

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
