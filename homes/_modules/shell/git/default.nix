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
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "https";
        prompt = "enabled";
        prefer_editor_prompt = "disabled";
        aliases = {
          co = "pr checkout";
        };
        telemetry = "disabled";
      };
    };
    programs.gh-dash.enable = true;
    programs.lazygit.enable = true;
    programs.git.enable = true;
  };
}
