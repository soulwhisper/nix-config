{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./claude
    ./packages.nix
  ];

  options.modules.development = {
    enable = lib.mkEnableOption "development";
  };
}
