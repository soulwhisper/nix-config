{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.development.omp;
in
{
  options.modules.development.omp = {
    enable = lib.mkEnableOption "oh-my-pi coding agent";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a file containing the DeepSeek API key (sops-managed).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Non-secret: DeepSeek OpenAI-compatible endpoint
    home.sessionVariables.DEEPSEEK_BASE_URL = "https://api.deepseek.com/v1";

    # Secret: read API key from sops-managed tmpfs file at shell init.
    # This mirrors the claude-code wrapper pattern but is simpler — omp
    # reads DEEPSEEK_API_KEY natively; no binary wrapping needed.
    programs.fish.interactiveShellInit = lib.mkIf (cfg.authFile != null) ''
      if test -r "${cfg.authFile}"
        set -gx DEEPSEEK_API_KEY (string trim < "${cfg.authFile}")
      end
    '';
  };
}
