{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.security.1password-cli;
in
{
  options.modules.security.1password-cli = {
    enable = lib.mkEnableOption "1password-cli";
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        pkgs._1password-cli
      ];
    })
  ];
}