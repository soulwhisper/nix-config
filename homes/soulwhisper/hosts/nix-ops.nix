{
  config,
  lib,
  pkgs,
  ...
}: {
  modules = {
    kubernetes.enable = true;
    security._1password-cli.enable = true;
  };
}
