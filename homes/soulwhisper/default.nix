{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../_modules
    ./secrets
    ./hosts/${hostname}.nix
  ];

  modules = {
    development.enable = true;
    development.omp.enable = true;
    development.omp.authFile = config.sops.secrets."dev/deepseek/key".path;
    kubernetes.enable = true;
    security._1password-cli.enable = true;
    shell.atuin.authFile = config.sops.secrets."shell/atuin/auth".path;
  };
}
