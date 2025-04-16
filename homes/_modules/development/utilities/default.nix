{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.development;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      minijinja
      nixd
      nixfmt-rfc-style
      pre-commit
      yamllint
      unstable.govc
      unstable.helm-ls
      unstable.mise
      unstable.minio-client
    ];
    programs.fish = {
      interactiveShellInit = ''
        ${lib.getExe pkgs.unstable.mise} activate fish | source
      '';
    };
  };
}
