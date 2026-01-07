{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.deployment;
in {
  options.modules.deployment = {
    enable = lib.mkEnableOption "deployment";
  };

  config = {
    home.packages = [
      pkgs.nixos-rebuild
      pkgs.nvd
    ];
  };
}
