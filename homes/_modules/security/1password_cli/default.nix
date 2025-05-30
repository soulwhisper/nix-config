{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.security._1password-cli;
in {
  options.modules.security._1password-cli = {
    enable = lib.mkEnableOption "_1password-cli";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs._1password-cli
    ];
  };
}
