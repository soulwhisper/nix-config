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
    vmware.enable = lib.mkEnableOption "development-vmware";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        awscli2
        grype
        minijinja
        nixd
        nixfmt-rfc-style
        unstable.just
      ]
      ++ lib.optionals cfg.vmware.enable [
        unstable.govc
      ];
  };
}
