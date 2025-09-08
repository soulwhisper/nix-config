{
  hostname,
  lib,
  pkgs,
  ...
}: {
  # check first: https://daiderd.com/nix-darwin/manual/index.html
  config = {
    networking = {
      computerName = "soulwhisper-mba";
      hostName = hostname;
      localHostName = hostname;
    };

    # : test/temp apps list
    # :: not support brew yet
    # animeko: https://myani.org/downloads
    # cardforge: https://github.com/Card-Forge/forge/releases

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
        "nikitabobko/tap/aerospace"
        "bluestacks"
        "maa"
        "stats"
      ];
      masApps = {
        "DevHub" = 6476452351;
        "ReadKit" = 1615798039;
        # "Passepartout" = 1433648537;
        # "StopTheMadness Pro" = 6471380298;
      };
    };
  };
}
