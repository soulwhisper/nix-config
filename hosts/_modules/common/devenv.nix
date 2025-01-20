{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.modules.devenv;
in
{
  options.modules.devenv = {
    homelab.enable = lib.mkEnableOption "homelab-devenv";
  };

  config = lib.mkIf cfg.homelab.enable {
    environment.systemPackages = [
      pkgs.bashInteractive
      pkgs.devenv
    ];

    devenv.homelab =  {
      # python, ref: https://github.com/cachix/devenv/tree/main/examples/python-venv
      languages.python.enable = true;
      languages.python.venv.enable = true;
    };
  };
}