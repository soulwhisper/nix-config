{
  pkgs,
  lib,
  hostname,
  ...
}:
{
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
        "cidr"
      ];
      casks = [
        "orbstack"
        "transmit"
        "wireshark"
        "slack"
        "discord"
      ];
      masApps = {
        "Keka" = 470158793;
      };
    };
  };
}
