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
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        awscli2
        minijinja
        nixd
        nixfmt
        ssh-to-age # convert ssh keys for sops age recipients
        tio # serial terminal
      ])
      ++ (with pkgs.unstable; [
        just
        k6 # load testing
        minio-client # mc: homelab object storage (ports 9000-9001)
        nix-output-monitor # nom: readable nix builds, pairs with nvd
        nix-tree # closure size inspection
        nmap
        opentofu
        postgresql # psql/pg_dump for cnpg clusters
        prek
        rclone
        trivy # image/fs/iac vulnerability and misconfig scanning
        xh # http client
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
  };
}
