{
  lib,
  pkgs,
  ...
}: {
  modules = {
    deployment.nix.enable = true;
    development.enable = true;
    kubernetes.enable = true;
    security.gnugpg.enable = true;
    security._1password-cli.enable = true;
  };
}
