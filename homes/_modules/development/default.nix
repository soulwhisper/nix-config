{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.development;
in {
  options.modules.development = {
    enable = lib.mkEnableOption "development";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      minijinja
      nixd
      nixfmt-rfc-style
      pre-commit
      yamllint
      unstable.go-task
      unstable.govc
      unstable.helm-ls
      unstable.minio-client
    ];
    programs.mise.enable = true;
  };
}
