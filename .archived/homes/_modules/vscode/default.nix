{
  inputs,
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
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.unstable.vscode;
      profiles.default.extensions = let
        pkgs-ext = import inputs.nixpkgs {
          inherit (pkgs) system;
          config.allowUnfree = true;
          overlays = [inputs.nix-vscode-extensions.overlays.default];
        };
        marketplace = pkgs-ext.vscode-marketplace;
      in
        with marketplace; [
          # : based on sync

          ## Formatters & Linters
          christian-kohler.path-intellisense
          esbenp.prettier-vscode
          fnando.linter
          shardulm94.trailing-spaces
          sonarsource.sonarlint-vscode
          streetsidesoftware.code-spell-checker

          ## Git
          eamodio.gitlens
          github.remotehub

          ## Localization
          ms-ceintl.vscode-language-pack-zh-hans

          ## Programming support
          dbaeumer.vscode-eslint
          jnoortheen.nix-ide
          ms-python.python
          redhat.vscode-yaml
          samuelcolvin.jinjahtml
          savh.json5-kit

          ## Remote development
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode.remote-explorer

          ## Theme, Color prefer `modern dark`
          pkief.material-icon-theme

          ## Tools
          github.copilot
          ms-azuretools.vscode-containers
          ms-kubernetes-tools.vscode-kubernetes-tools
          signageos.signageos-vscode-sops

          ## Other
          aaron-bond.better-comments
          gruntfuggly.todo-tree
          johnpapa.vscode-peacock
          mutantdino.resourcemonitor
        ];
    };

    home.file = lib.genAttrs pathsToMakeWritable (_: {
      force = true;
      mutable = true;
    });
  };
}
