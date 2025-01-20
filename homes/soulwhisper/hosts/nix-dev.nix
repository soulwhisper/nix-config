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
  };
}