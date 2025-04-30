{
  config,
  lib,
  pkgs,
  ...
}: {
  # replace pre-commit and various linters
  # action/markdown/sops/yaml checks are disabled
  git-hooks = {
    excludes = [ "generated\.(json|nix)$" "flake.lock" "\.github" "\.json5$"];
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
    };
  };
}
