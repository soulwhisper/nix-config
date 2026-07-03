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
  options.modules.development = {
    enable = lib.mkEnableOption "development";
    agent.authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a file containing the DeepSeek API key (sops-managed).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        awscli2
        minijinja
        nixd
        nixfmt
        tio # serial terminal
      ])
      ++ (with pkgs.unstable; [
        just
        prek
      ]);

    # mise — runtime version manager; preferred over direnv.
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
          "github:rtk-ai/rtk" = "latest";
        }
        // lib.optionalAttrs (config.modules.kubernetes.enable) {
          "github:home-operations/flate" = "latest";
        };
      };
    };

    # omp - current coding agent, replace claude-code
    programs.fish.interactiveShellInit = lib.mkIf (cfg.agent.authFile != null) ''
      rtk init -g --agent pi
      if test -r "${cfg.agent.authFile}"
        set -gx DEEPSEEK_API_KEY (string trim < "${cfg.agent.authFile}")
      end
    '';
  };
}
