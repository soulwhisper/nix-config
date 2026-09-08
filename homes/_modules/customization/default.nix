{
  config,
  lib,
  pkgs,
  ...
}: let
  # "${config.xdg.configHome}" = "~/.config"
  # "${config.xdg.dataHome}" = "~/.local/share"
  ghostty-path =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application Support/com.mitchellh.ghostty/config"
    else "${config.xdg.configHome}/ghostty/config";

  opencode-path = "${config.xdg.dataHome}/opencode/opencode.json";

  rime-path =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Rime"
    else "${config.xdg.dataHome}/fcitx5/rime";
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
    # :: create-if-absent deploy: nix installs the file only when no config
    #    exists, then leaves it alone — manual edits and `aerospace reload-config`
    #    workflows survive every rebuild/switch. To restore the repo version:
    #      rm ~/.config/aerospace/aerospace.toml && <home-manager switch>
    home.activation.aerospaceConfig = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        target="${config.xdg.configHome}/aerospace/aerospace.toml"
        if [ ! -e "$target" ]; then
          run mkdir -p "$(dirname "$target")"
          run install -m 0644 ${./aerospace.toml} "$target"
        else
          run echo "aerospace.toml exists, leaving untouched: $target"
        fi
      ''
    );

    # : Karabiner for MacOS
    # :: Switch Input Method => HyperCaps - Space
    # xdg.configFile."${config.xdg.configHome}/karabiner/karabiner.json" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    #   enable = false;
    #   source = ./karabiner.json;
    # };
  };
}
