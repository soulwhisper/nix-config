{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.development;
in {
  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        awscli2
        minijinja
        nixd
        nixfmt
        tio # serial terminal
      ])
      ++ (with pkgs.unstable; [
        just
        prek
      ]);
  };
}
