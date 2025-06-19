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

    users.users.soulwhisper = {
      name = "soulwhisper";
      home = "/Users/soulwhisper";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = lib.strings.splitString "\n" (builtins.readFile ../../homes/soulwhisper/config/ssh/ssh.pub);
    };

    system.primaryUser = "soulwhisper"; # since 25.05, nix-darwin needs this to be functional

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      sudo chsh -s /run/current-system/sw/bin/fish soulwhisper
    '';

    # : test/temp apps list
    # :: not support brew yet
    # animeko: https://myani.org/downloads
    # :: todo
    # MS Office (365)
    homebrew = {
      taps = [
      ];
      brews = [
      ];
      casks = [
        # :: storage
        "transmission"

        # :: productivity
        "discord"
        "wireshark"
      ];
      masApps = {
        "DevHub" = 6476452351;
        "ReadKit" = 1615798039;
        "Windows App" = 1295203466;
        # "Passepartout" = 1433648537;
        # "StopTheMadness Pro" = 6471380298;
      };
    };
  };
}
