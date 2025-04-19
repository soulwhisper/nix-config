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
    mise.enable = lib.mkEnableOption "development-mise";
    vmware.enable = lib.mkEnableOption "development-vmware";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        minijinja
        nixd
        nixfmt-rfc-style
        unstable.go-task
        unstable.minio-client
      ]
      ++ lib.optionals cfg.vmware.enable [
        unstable.govc
      ];

    programs.direnv.enable = lib.mkIf (!cfg.mise.enable) true;
    programs.mise.enable = lib.mkIf cfg.mise.enable true;
  };
}
