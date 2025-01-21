{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.terminal.ghostty;
in {
  options.modules.terminal.ghostty = {
    enable = lib.mkEnableOption "ghostty";
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        # Theme config
        theme = "catppuccin-mocha";
        # Fonts
        font-family = "MonaspiceKr Nerd Font Mono";
        font-family-bold = "MonaspiceKr Nerd Font Bold";
        font-family-italic = "MonaspiceKr Nerd Font Italic";
        font-family-bold-italic = "MonaspiceKr Nerd Font Bold Italic";
        font-size = "12";
        font-thicken = true;
        # macOS specific
        macos-auto-secure-input = true;
        macos-secure-input-indication = true;
        window-padding-balance = false;
        window-padding-x = "10";
        window-padding-y = "10,2";
        # Application settings
        auto-update = "download";
        auto-update-channel = "stable";
        clipboard-trim-trailing-spaces = true;
        shell-integration = "detect";
        # Window settings
        window-height = "45";
        window-width = "180";
      };
    };
  };
}
