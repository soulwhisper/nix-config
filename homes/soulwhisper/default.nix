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
    deployment.nix.enable = true;
    editor = {
      nvim = {
        enable = true;
        makeDefaultEditor = true;
      };

      vscode = {
        userSettings = lib.importJSON ./config/editor/vscode/settings.json;
        extensions = let
          # inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}) vscode-marketplace;
          # allowUnfree fix: https://github.com/nix-community/nix-vscode-extensions/issues/99#issuecomment-2703326753
          pkgs-ext = import inputs.nixpkgs {
            inherit (pkgs) system;
            config.allowUnfree = true;
            overlays = [inputs.nix-vscode-extensions.overlays.default];
          };
          marketplace = pkgs-ext.vscode-marketplace;
        in
          # with vscode-marketplace; [
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

    security = {
      ssh = {
        enable = true;
        matchBlocks = {
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
      };
    };

    shell = {
      atuin = {
        enable = true;
        package = pkgs.unstable.atuin;
        flags = [
          "--disable-up-arrow"
        ];
        settings = {
          # use official sync server for now
          #sync_address = "https://atuin.homelab.internal";
          key_path = config.sops.secrets.atuin_key.path;
          auto_sync = true;
          sync_frequency = "1m";
          search_mode = "fuzzy";
          sync = {
            records = true;
          };
        };
      };

      fish.enable = true;

      git = {
        enable = true;
        username = "Hekatos Noir";
        email = "soulwhisper@outlook.com";
        signingKey = "DF405879732AE5F2";
      };

      go-task.enable = true;
    };

    themes = {
      catppuccin = {
        enable = true;
        flavor = "mocha";
      };
    };
  };
}
