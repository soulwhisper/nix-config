{
  config,
  lib,
  pkgs,
  ...
}: let
  tmuxTerm = lib.mkIf pkgs.;
in {
  imports = [
    ./ghostty
  ];
  config = {
    programs.tmux = {
      enable = true;
      clock24 = true;
      newSession = true;
      terminal = if pkgs.stdenv.hostPlatform.isDarwin then "ghostty" else "xterm-256color";
    };

    # zellij still have bugs and conflict with tmux, backspace bug: https://github.com/zellij-org/zellij/issues/4024
  };
}
