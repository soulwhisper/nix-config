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
    development.claude.authFile = config.sops.secrets."dev/claude/auth".path;
    kubernetes.enable = true;
    security._1password-cli.enable = true;
    shell.atuin.authFile = config.sops.secrets."shell/atuin/auth".path;
  };
}
