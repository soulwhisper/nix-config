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
    shell = {
      atuin.key_path = config.sops.secrets.atuin_key.path;
    };
  };
}
