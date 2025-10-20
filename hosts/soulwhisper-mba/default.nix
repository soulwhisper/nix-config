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
      unstable.forge-mtg # cardforge, https://github.com/Card-Forge/forge/releases
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
        "unity"
        "wireshark-app"

        # :: test
        "bluestacks"
        "maa"
        "roonbridge"
        "stats"
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
