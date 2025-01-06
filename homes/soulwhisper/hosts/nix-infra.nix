{
  lib,
  pkgs,
  ...
}:
{
  modules = {
    development.enable = true;
    kubernetes.enable = true;
    security.gnugpg.enable = true;
    security._1password-cli.enable = true;

    # disable mise in nixos, use containers instead.

  };
}