{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    home.packages = [
      pkgs.nixos-rebuild
      pkgs.nvd
    ];
  };
}
