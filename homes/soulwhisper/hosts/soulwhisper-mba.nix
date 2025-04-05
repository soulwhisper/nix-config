{
  lib,
  pkgs,
  ...
}: {
  modules = {
    development.enable = true;
    editor = {
      vscode = {
        enable = true;
        userSettings = lib.importJSON ../config/editor/vscode/settings.json;
      };
    };
    kubernetes.enable = true;
    security.gnugpg.enable = true;
    security._1password-cli.enable = true;
  };
}
