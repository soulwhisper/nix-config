{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.development;
in
{
  config = lib.mkIf cfg.enable {
    # mise — runtime version manager; preferred over direnv.
    # All tools here are development-facing (prek, omp, rtk, flate).
    programs.mise = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      globalConfig = {
        env = {
          "RTK_TELEMETRY_DISABLED" = "true";
        };
        settings = {
          experimental = true;
          disable_hints = [ "*" ];
          always_keep_download = false;
          always_keep_install = false;
          idiomatic_version_file_enable_tools = [
            "node"
            "python"
            "go"
            "rust"
          ];
        };
        tools = {
          prek = "latest";
          "github:can1357/oh-my-pi" = "latest";
          # rtk init: 'rtk init -g --agent pi' for omp, 'rtk init -g' for claude-code
          "github:rtk-ai/rtk" = "latest";
        }
        // lib.optionalAttrs (config.modules.kubernetes.enable) {
          "github:home-operations/flate" = "latest";
        };
      };
    };
  };
}
