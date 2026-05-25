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

    # prefer unstable for implementing platform-specific fixes
    environment.systemPackages = with pkgs.unstable; [
      # cardforge, https://github.com/Card-Forge/forge/releases
      forge-mtg
      # music
      beets # music library manager
      picard # qt music tagger
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
