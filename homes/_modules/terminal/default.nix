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
    # zellij use tmux inside, conflict with native tmux; also dont set xterm in tmux
    programs.zellij.enable = true;
  };
}
