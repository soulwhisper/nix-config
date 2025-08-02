{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./packages.nix
    ./k9s.nix
  ];

  options.modules.kubernetes = {
    enable = lib.mkEnableOption "kubernetes";
  };
}
