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

    # zellij use tmux inside, conflict with native tmux
    programs.zellij.enable = true;
  };
}
