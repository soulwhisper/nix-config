{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules
    ./secrets
    ./hosts/${hostname}.nix
  ];

  modules = {
    editor = {
      vscode = {
        extensions = let
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
            esbenp.prettier-vscode
            fnando.linter
            ionutvmi.path-autocomplete
            shardulm94.trailing-spaces

            ## Git
            eamodio.gitlens
            github.remotehub

            ## Localization
            ms-ceintl.vscode-language-pack-zh-hans

            ## Programming support
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
            ms-azuretools.vscode-containers
            ms-kubernetes-tools.vscode-kubernetes-tools
            signageos.signageos-vscode-sops

            ## Other
            gruntfuggly.todo-tree
            mutantdino.resourcemonitor
          ];
      };
    };

    security.ssh.matchBlocks = {
      "nix-dev.homelab.internal" = {
        port = 22;
        user = "soulwhisper";
        forwardAgent = true;
      };
      "nix-nas.homelab.internal" = {
        port = 22;
        user = "soulwhisper";
        forwardAgent = true;
      };
      "nix-infra.homelab.internal" = {
        port = 22;
        user = "soulwhisper";
        forwardAgent = true;
      };
    };

    shell = {
      atuin = {
        enable = true;
        # use official sync server for now
        # sync_address = "https://atuin.homelab.internal";
        key_path = config.sops.secrets.atuin_key.path;
      };
      git = {
        enable = true;
        username = "Hekatos Noir";
        email = "soulwhisper@outlook.com";
        signingKey = "DF405879732AE5F2";
      };
    };
  };
}
