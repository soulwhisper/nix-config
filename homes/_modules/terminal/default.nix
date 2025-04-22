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
    # keep config simple
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      terminal = "tmux-256color";
      plugins = with pkgs; [
        tmuxPlugins.battery
        tmuxPlugins.cpu
      ];
      extraConfig = ''
        # Configure the catppuccin plugin
        set -g @catppuccin_flavor "mocha"
        set -g @catppuccin_window_status_style "rounded"

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

    # zellij still have bugs and conflict with tmux, ref:https://github.com/zellij-org/zellij/issues/4024
  };
}
