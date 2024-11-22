{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.development;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = (with pkgs; [
      minijinja
      nixd
      nixfmt-rfc-style
      pre-commit
      yamllint
      unstable.govc
      unstable.helm-ls
      unstable.minio-client
    ]) ++
    [
      inputs.nix-inspect.packages.${pkgs.system}.default
    ];
  };
}
