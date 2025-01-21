{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = {
    # This will enable devenv at all hosts,
    # use "devenv init", ref: https://devenv.sh/basics/
    environment.systemPackages = [
      pkgs.bashInteractive
      pkgs.devenv
      pkgs.direnv
    ];
  };
}