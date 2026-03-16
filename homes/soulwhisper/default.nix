{
  config,
  hostname,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules
    ./secrets
    ./hosts/${hostname}.nix
  ];

  modules = {
    development.enable = true;
    kubernetes.enable = true;
    security._1password-cli.enable = true;

    shell = {
      atuin.key_path = config.sops.secrets.atuin_key.path;
    };
  };
}
