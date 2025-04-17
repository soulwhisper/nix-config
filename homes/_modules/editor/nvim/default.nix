{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.editor.nvim;
in {
  options.modules.editor.nvim = {
    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = {
    programs.neovim = {
      enable = true;
      defaultEditor = cfg.defaultEditor;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
    };

    # Use Neovim as the editor for git commit messages
    programs.git.extraConfig.core.editor = "nvim";
    # Set Neovim as the default app for manual pages
    home.sessionVariables.MANPAGER = "nvim +Man!";
  };
}
