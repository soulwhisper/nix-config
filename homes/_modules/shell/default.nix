{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./atuin
    ./fish
    ./git
    ./starship
    ./utilities
  ];
  config = {
    programs.bash.enable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin true;
  };
}
