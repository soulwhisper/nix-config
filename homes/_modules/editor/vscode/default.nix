{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.editor.vscode;
  userDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application Support/Code/User"
    else "${config.xdg.configHome}/Code/User";
  configFilePath = "${userDir}/settings.json";

  pathsToMakeWritable = lib.flatten [
    configFilePath
  ];
  settingsFile = lib.importJSON ./settings.json;
in {
  options.modules.editor.vscode = {
    enable = lib.mkEnableOption "vscode";
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
    };
    userSettings = lib.mkOption {
      type = lib.types.attrs;
      default = settingsFile;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.unstable.vscode;
      mutableExtensionsDir = true;

      inherit (cfg) extensions;
      inherit (cfg) userSettings;
    };

    home.file = lib.genAttrs pathsToMakeWritable (_: {
      force = true;
      mutable = true;
    });
  };
}
