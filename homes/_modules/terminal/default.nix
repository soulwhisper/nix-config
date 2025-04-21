{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ghostty
  ];
  config = {
    programs.tmux = {
      enable = true;
      clock24 = true;
      newSession = true;
      terminal = "xterm-256color";
    };

    programs.zellij = {
      enable = true;
      enableFishIntegration = true;
      attachExistingSession = true;
      exitShellOnExit = false;
    };
  };
}
