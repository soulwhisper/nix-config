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
      terminal = "screen-256color";
    };

    programs.zellij.enable = true;
  };
}
