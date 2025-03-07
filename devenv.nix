{
  config,
  lib,
  pkgs,
  ...
}: {
  # replace pre-commit and various linters
  # action cant modify actions without PAT
  git-hooks = {
    excludes = ["\.json5$" "generated\.(json|nix)$" "nix-build\.ya?ml$" "update-nvfetcher\.ya?ml$" "flake.lock" "\.sops\.ya?ml$" "\.github"];
    hooks = {
      alejandra.enable = true;
      prettier = {
        enable = true;
        settings = {
          tab-width = 2;
          trailing-comma = "es5";
          use-tabs = false;
        };
      };
      yamllint = {
        enable = true;
        settings.configuration = ''
          ---
          extends: default
          rules:
            truthy:
              allowed-values: ["true", "false", "on"]
            comments:
              min-spaces-from-content: 1
            line-length: disable
            braces:
              min-spaces-inside: 0
              max-spaces-inside: 1
            brackets:
              min-spaces-inside: 0
              max-spaces-inside: 0
            indentation: enable
        '';
      };
      # disable this check when using ci, hints only
      markdownlint = lib.optionalAttrs (!config.devenv.isTesting) {
        enable = true;
        files = "\.md$";
        settings.configuration = {
          MD013.line-length = 120;
          MD024.siblings-only = true;
          MD033 = false;
          MD034 = false;
        };
      };
      # disable this check when using ci, hints only
      pre-commit-hook-ensure-sops = lib.optionalAttrs (!config.devenv.isTesting) {
        enable = true;
        files = "kubernetes/.*\.sops\.(toml|ya?ml)$";
      };
    };
  };

  # See full reference at https://devenv.sh/reference/options/
}
