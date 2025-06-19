{
  config,
  lib,
  pkgs,
  ...
}: let
  userDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application Support/com.mitchellh.ghostty"
    else "${config.xdg.configHome}/ghostty";
in {
  config = {
    # install ghostty via homebrew, macos only;
    # https://github.com/catppuccin/ghostty

    xdg.configFile."${userDir}/config" = {
      enable = true;
      text = ''
        # Theme config
        theme = catppuccin-mocha
        # Fonts
        font-size = 10
        font-family = Jetbrains Nerd Font Mono Light
        font-thicken = false
        # macOS specific
        macos-auto-secure-input = true
        macos-secure-input-indication = true
        window-padding-balance = false
        window-padding-x = 10
        window-padding-y = 10,2
        # Application settings
        auto-update = download
        auto-update-channel = stable
        clipboard-trim-trailing-spaces = true
        shell-integration = detect
        # Window settings
        window-height = 45
        window-width = 180
      '';
    };
  };
}
