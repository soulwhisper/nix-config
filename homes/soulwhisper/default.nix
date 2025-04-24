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
            # Language
            ms-ceintl.vscode-language-pack-zh-hans

            # Themes
            catppuccin.catppuccin-vsc
            catppuccin.catppuccin-vsc-icons

            # Language support
            golang.go
            jinliming2.vscode-go-template
            helm-ls.helm-ls
            jnoortheen.nix-ide
            savh.json5-kit
            ms-azuretools.vscode-docker
            ms-python.python
            redhat.vscode-yaml
            tamasfe.even-better-toml

            # Formatters
            esbenp.prettier-vscode
            shardulm94.trailing-spaces

            # Linters
            fnando.linter

            # Remote development
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh

            # Markdown
            davidanson.vscode-markdownlint
            shd101wyy.markdown-preview-enhanced

            # Other
            eamodio.gitlens
            gruntfuggly.todo-tree
            ionutvmi.path-autocomplete
            luisfontes19.vscode-swissknife
            ms-kubernetes-tools.vscode-kubernetes-tools
            signageos.signageos-vscode-sops
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
      navi.enable = true;
    };
  };
}
