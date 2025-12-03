{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    programs.delta.enable = true;
    programs.delta.enableGitIntegration = true;
    programs.gh.enable = true;
    programs.gh-dash.enable = true;
    programs.lazygit.enable = true;
    programs.git.enable = true;
    programs.git.signing.signByDefault = true;
  };
}
