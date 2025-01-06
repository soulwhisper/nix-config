{
  description = "soulwhisper Nix Flake";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Flake-parts - Simplify Nix Flakes with the module system
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # home-manager - home user+dotfile manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin - nix modules for darwin (MacOS)
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix - secrets with mozilla sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # VSCode community extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin - Soothing pastel theme for Nix
    catppuccin = {
      url = "github:catppuccin/nix";
    };

    # Nix Inspect - Interactive tui for inspecting nix configs
    nix-inspect = {
      url = "github:bluskript/nix-inspect";
    };

    # Talhelper - A tool to help create Talos Kubernetes clusters
    talhelper = {
      url = "github:budimanjojo/talhelper";
    };

    # Krewfile - Declarative krew plugin management
    krewfile = {
      url = "github:brumhard/krewfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    flake-parts,
    ...
  } @inputs:
  let
    mkPkgsWithSystem =
      system:
      import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues (import ./overlays { inherit inputs; });
        config.allowUnfree = true;
      };
    mkSystemLib = import ./lib/mkSystem.nix {inherit inputs mkPkgsWithSystem;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      perSystem = {
        system,
        inputs',
        pkgs,
        ...
      }:
      {
        # override pkgs used by everything in `perSystem` to have my overlays
        _module.args.pkgs = mkPkgsWithSystem system;
        # accessible via `nix build .#<name>`
        packages = import ./pkgs {inherit pkgs inputs;};
      };

      imports = [];

    flake = {
        nixosConfigurations = {
          # nixos builds
          nix-vpn = mkSystemLib.mkNixosSystem "x86_64-linux" "nix-vpn";
          nix-nas = mkSystemLib.mkNixosSystem "x86_64-linux" "nix-nas";
          nix-infra = mkSystemLib.mkNixosSystem "x86_64-linux" "nix-infra";
        };

        darwinConfigurations = {
          # darwin builds
          soulwhisper-mba = mkSystemLib.mkDarwinSystem "aarch64-darwin" "soulwhisper-mba";
        };

        # Convenience output that aggregates the outputs for home, nixos.
        # Also used in ci to build targets generally.
        ciSystems =
          let
            nixos =
              inputs.nixpkgs.lib.genAttrs
              (builtins.attrNames inputs.self.nixosConfigurations)
              (attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel);
            darwin =
              inputs.nixpkgs.lib.genAttrs
              (builtins.attrNames inputs.self.darwinConfigurations)
              (attr: inputs.self.darwinConfigurations.${attr}.system);
          in
            nixos // darwin;
    };
  };
}
