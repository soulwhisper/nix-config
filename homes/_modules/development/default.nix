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
        curlie # api test like curl
        grype
        httpie # api test
        kopia
        minijinja
        nixd
        nixfmt-rfc-style
        unstable.just
        unstable.mise
        unstable.oha # http load generator
      ]
      ++ lib.optionals cfg.vmware.enable [
        unstable.govc
      ];
  };
}
