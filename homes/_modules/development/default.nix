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
    home.packages = with pkgs;
      [
        awscli2
        minijinja
        nixd
        nixfmt
        nixfmt-tree # treefmt
        tio # serial terminal
        unstable.just
        unstable.prek
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        unstable.claude-code
      ];
  };
}
