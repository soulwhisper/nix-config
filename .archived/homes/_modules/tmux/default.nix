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
    # C-x w      open window tree
    # Alt + =/-  pre/nxt session
    # Alt + ,/.  pre/nxt window
    # Alt + </>  left/right window swap
    # C-x v      horizontal split (keep path)
    # C-x s      vertical split (keep path)
    # C-x V      horizontal merge with pane tree
    # C-x S      vertical merge with pane tree
    # C-x n      copy-mode
    # C-x p      paste-buffer
    ## copy mode:
    # n          default style
    # v          vim style
    # y          copy
    # K/J        up/down scroll
    # ESC/i      exit
  };
}
