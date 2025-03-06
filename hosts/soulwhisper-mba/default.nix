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

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      sudo chsh -s /run/current-system/sw/bin/fish soulwhisper
    '';

    # testing apps list
    homebrew = {
      taps = [
      ];
      brews = [
        "derailed/popeye/popeye" # k8s live cluster linter
        "goreleaser/tap/goreleaser"
      ];
      casks = [
        "discord"
        "brewforge/chinese/easytier"
        "halloy"
        "lazygit"
        "maccy"
        "orbstack"
        "rectangle-pro"
        "slack"
        "swiftbar"
        "tableplus"
        "transmit"
        "wireshark"
      ];
      masApps = {
        "Passepartout" = 1433648537;
        "ReadKit" = 1615798039;
        # "Windows App" = 1295203466;
        # "StopTheMadness Pro" = 6471380298; # not owned yet
      };
    };
  };
}
