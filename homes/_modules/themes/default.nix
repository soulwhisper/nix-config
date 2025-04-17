{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.themes.catppuccin;
in {
  options.modules.themes.catppuccin = {
    flavor = lib.mkOption {
      type = lib.types.str;
      default = "mocha";
    };
  };

  config = {
    catppuccin.flavor = cfg.flavor;
  };
}
