{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    home.packages = with pkgs; [
      unstable.difftastic
      unstable.gitleaks
    ];

    programs.delta.enable = true;
    programs.delta.enableGitIntegration = true;
    programs.gh.enable = true;
    programs.gh-dash.enable = true;
    programs.lazygit.enable = true;
    programs.git.enable = true;
    programs.git.signing.signByDefault = true;
  };
}
