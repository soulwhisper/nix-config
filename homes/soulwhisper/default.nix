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
    shell.atuin.authFile = config.sops.secrets."shell/atuin/auth".path;
  };
}
