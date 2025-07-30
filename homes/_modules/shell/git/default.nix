{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    programs.gh.enable = true;
    programs.gh-dash.enable = true;
    programs.lazygit.enable = true;
    programs.git = {
      enable = true;
      delta.enable = true;
      signing.signByDefault = true;
    };
  };
}
