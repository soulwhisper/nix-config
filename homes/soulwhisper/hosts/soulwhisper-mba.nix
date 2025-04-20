{
  lib,
  pkgs,
  ...
}: {
  modules = {
    development.enable = true;
    editor.vscode.enable = true;
    kubernetes.enable = true;
    security._1password-cli.enable = true;
  };
}
