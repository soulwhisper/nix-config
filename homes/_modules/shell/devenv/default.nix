{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (pkgs.stdenv) isDarwin;

  cfg = config.modules.shell.devenv;
in
{
  options.modules.shell.devenv = {
    python.enable = lib.mkEnableOption "python-venv";
  };

  config = {
    devenv.shell.python = lib.mkIf cfg.python.enable {
      # python, ref: https://github.com/cachix/devenv/tree/main/examples/python-venv
      languages.python.enable = true;
      languages.python.venv.enable = true;
    };
  };
}