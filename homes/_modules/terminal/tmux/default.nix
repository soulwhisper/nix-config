{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    # not using home-manager tmux config
    home.packages = [pkgs.tmux];
    xdg.configFile."tmux/tmux.conf".source = ./tmux.conf;

    # Prefix = ctrl + x
    # C-x c      new window
    # C-x b      turn current pane to window
    # C-x w      show window tree
    # alt + =/-  pre/nxt session
    # alt + ,/.  pre/nxt window
    # C-x v      horizontal split (keep path)
    # C-x s      vertical split (keep path)
    # C-x V      horizontal merge
    # C-x S      vertical merge
    # C-x n      copy-mode
    # C-x p      paste-buffer

    # zellij still have bugs and conflict with tmux, ref:https://github.com/zellij-org/zellij/issues/4024
  };
}
