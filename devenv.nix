{
  lib,
  pkgs,
  config,
  ...
}: {
  # replace pre-commit and various linters
  git-hooks = {
    # exclude = "_assets\/.*";
    hooks = {
      actionlint = {
        enable = true;
        files = "github\/workflows\/.*\.(yml|yaml)$";
      };
      alejandra = {
        enable = true;
        settings.exclude = [
          "generated.nix"
        ];
      };
      prettier = {
        enable = true;
        settings = {
          end-of-line = "lf";
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
      check-added-large-files.enable = true;
      check-merge-conflicts.enable = true;
      check-executables-have-shebangs.enable = true;
      end-of-file-fixer.enable = true;
      fix-byte-order-marker.enable = true;
      # trim-trailing-whitespace.enable = true;
      mixed-line-endings.enable = true;
    };
  };

  # See full reference at https://devenv.sh/reference/options/
}
