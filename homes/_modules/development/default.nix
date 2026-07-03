{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./omp
    ./mise
    ./packages.nix
  ];

  options.modules.development = {
    enable = lib.mkEnableOption "development";
  };
}
