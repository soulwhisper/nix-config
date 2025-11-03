{
  hostname,
  lib,
  pkgs,
  ...
}: {
  # ref:https://daiderd.com/nix-darwin/manual/index.html
  config = {
    networking = {
      computerName = "soulwhisper-mba";
      hostName = hostname;
      localHostName = hostname;
    };

    # : test/temp apps list

    environment.systemPackages = with pkgs; [
      # cardforge, https://github.com/Card-Forge/forge/releases
      unstable.forge-mtg.overrideAttrs (oldAttrs: {
        buildInputs = lib.lists.remove alsa-lib oldAttrs.buildInputs;
        preFixup = let
          oldPreFixup = oldAttrs.preFixup;
          newPreFixup = builtins.replaceStrings
            [ "lib.makeLibraryPath [ libGL alsa-lib ]" ]
            [ "lib.makeLibraryPath [ libGL ]" ]
          oldPreFixup;
        in newPreFixup;
      })
    ];

    homebrew = {
      taps = [
        "nikitabobko/tap"
      ];
      brews = [
      ];
      casks = [
        # :: storage
        "transmission"

        # :: productivity
        "audacity"
        "squirrel-app"
        "wireshark-app"

        # :: test
        "acorn"
        "betterdisplay"
        "bluestacks"
        "little-snitch"
        "maa"
        "stats"
        "vanilla"
      ];
      masApps = {
        "DevHub" = 6476452351;
        "ReadKit" = 1615798039;
        "iCost" = 1484262528;
        # "Passepartout" = 1433648537;
        # "StopTheMadness Pro" = 6471380298;
      };
    };
  };
}
