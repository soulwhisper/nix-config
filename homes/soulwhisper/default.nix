{
  pkgs,
  lib,
  config,
  inputs,
  hostname,
  flake-packages,
  ...
}:
{
  imports = [
    ../_modules
    ./secrets
    ./hosts/${hostname}.nix
  ];

  modules = {
    editor = {
      nvim = {
        enable = true;
        package = flake-packages.${pkgs.system}.nvim;
        makeDefaultEditor = true;
      };

      vscode = {
        userSettings = lib.importJSON ./config/editor/vscode/settings.json;
        extensions = let
          inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}) vscode-marketplace;
        in
          with vscode-marketplace; [
            # Themes
            catppuccin.catppuccin-vsc
            thang-nm.catppuccin-perfect-icons

            # Language support
            golang.go
            hashicorp.terraform
            helm-ls.helm-ls
            jnoortheen.nix-ide
            mrmlnc.vscode-json5
            ms-azuretools.vscode-docker
            ms-python.python
            redhat.ansible
            redhat.vscode-yaml
            tamasfe.even-better-toml

            # Formatters
            esbenp.prettier-vscode

            # Linters
            davidanson.vscode-markdownlint
            fnando.linter

            # Remote development
            ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh

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
          "nix-vm.homelab.internal" = {
            port = 22;
            user = "soulwhisper";
            forwardAgent = true;
          };
          "nix-nas.homelab.internal" = {
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
#          sync_address = "https://atuin.homelab.internal";
# current, use official sync server
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
