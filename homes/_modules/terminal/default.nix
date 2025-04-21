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

      baseIndex = 1;
      clock24 = true;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      shortcut = "x";

      terminal = if pkgs.stdenv.hostPlatform.isDarwin then "ghostty" else "tmux-256color";
      plugins = with pkgs; [
        tmuxPlugins.battery
        tmuxPlugins.cpu
      ];
      extraConfig = ''
        # Configure the catppuccin plugin
        set -g @catppuccin_flavor "mocha"
        set -g @catppuccin_window_status_style "rounded"

        # Make index start from 1
        set -g base-index 1
        setw -g pane-base-index 1

        # Make the status line pretty and add some modules
        set -g status-right-length 100
        set -g status-left-length 100
        set -g status-left ""
        set -g status-right "#{E:@catppuccin_status_application}"
        set -agF status-right "#{E:@catppuccin_status_cpu}"
        set -ag status-right "#{E:@catppuccin_status_session}"
        set -ag status-right "#{E:@catppuccin_status_uptime}"
        set -agF status-right "#{E:@catppuccin_status_battery}"
      '';
    };

    # https://github.com/89iuv/dotfiles/blob/master/tmux/.tmux.conf

    # zellij still have bugs and conflict with tmux, backspace bug: https://github.com/zellij-org/zellij/issues/4024
  };
}
