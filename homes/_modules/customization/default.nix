{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    # : Karabiner for macOS
    # :: Switch Input Method => HyperCaps - Space
    xdg.configFile."${config.xdg.configHome}/karabiner/karabiner.json" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      source = ./karabiner.json;
    };

    # : Ghostty for macOS
    # :: Package installed via homebrew
    # :: ssh-integration will be included in 1.1.4
    xdg.configFile."Library/Application Support/com.mitchellh.ghostty/config" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      text = ''
        # Theme config
        theme = catppuccin-mocha
        # Fonts
        font-size = 13
        font-family = Jetbrains Nerd Font Mono Light
        font-thicken = false
        # macOS specific
        macos-auto-secure-input = false
        window-colorspace = display-p3
        # Application settings
        auto-update = off
        clipboard-trim-trailing-spaces = true
        shell-integration-features = ssh-env,ssh-terminfo,sudo
        # Window settings
        window-height = 45
        window-width = 180
      '';
    };
  };
}
