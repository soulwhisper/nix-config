{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./packages.nix
    ./claude.nix
  ];

  options.modules.development = {
    enable = lib.mkEnableOption "development";
  };
}
