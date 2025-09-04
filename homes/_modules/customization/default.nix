{
  config,
  lib,
  pkgs,
  ...
}: let
  ghostty-path = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/com.mitchellh.ghostty/config"
  else
    "${config.xdg.configHome}/.config/ghostty/config";

  rime-path = if pkgs.stdenv.hostPlatform.isDarwin then
    "${config.xdg.configHome}/Library/Rime"
  else
    "${config.xdg.configHome}/.local/share/fcitx5/rime";
in {
  config = {
    # : Ghostty
    # :: MacOS package installed via homebrew
    # :: ssh-integration will be included in 1.1.4
    xdg.configFile.ghostty-path = {
      enable = true;
      text = ''
        # Theme config
        theme = catppuccin-mocha
        # Fonts
        font-size = 13
        font-family = Jetbrains Nerd Font Mono Light
        font-thicken = false
        # Application settings
        auto-update = download
        auto-update-channel = stable
        clipboard-trim-trailing-spaces = true
        shell-integration-features = ssh-env,ssh-terminfo,sudo
        # Window settings
        window-height = 45
        window-width = 180
        # macOS specific
        macos-auto-secure-input = false
        macos-option-as-alt = left
      '';
    };

    # : Rime Moqi Yinxing
    # :: ref:https://github.com/gaboolic/rime-shuangpin-fuzhuma
    xdg.configFile.rime-path = {
      enable = true;
      force = true;
      recursive = true;
      source = pkgs.rime-moqi-yinxing;
    };

    # : Aerospace for MacOS
    # :: MacOS package installed via homebrew
    xdg.configFile."${config.xdg.configHome}/aerospace/aerospace.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      source = ./aerospace.toml;
    };

    # : Karabiner for MacOS
    # :: Switch Input Method => HyperCaps - Space
    xdg.configFile."${config.xdg.configHome}/karabiner/karabiner.json" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      source = ./karabiner.json;
    };
  };
}
