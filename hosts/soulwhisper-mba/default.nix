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

    environment.systemPackages = with pkgs; [
      # cardforge, https://github.com/Card-Forge/forge/releases
      unstable.forge-mtg
    ];

    # test apps list
    homebrew = {
      taps = [
      ];
      brews = [
      ];
      casks = [
        # "betterdisplay"
        "calibre"
        "openclaw"
        "little-snitch"
        "qlab"
        "wireshark-app"
      ];
      masApps = {
        # "StopTheMadness Pro" = 6471380298;
        # "Passepartout" = 1433648537;
      };
    };
  };
}
