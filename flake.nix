{
  description = "soulwhisper's Nix Flake";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # home-manager - home user+dotfile manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin - nix modules for darwin (MacOS)
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # catppuccin - Soothing pastel theme for Nix
    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # sops-nix - secrets with mozilla sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko - declarative disk partitioning and formatting
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Krewfile - Declarative krew plugin management
    krewfile = {
      url = "github:brumhard/krewfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      mkPkgsWithSystem =
        system:
        import inputs.nixpkgs {
          localSystem = system;
          overlays = builtins.attrValues (import ./overlays { inherit inputs; });
          config.allowUnfree = true;
        };
      mkSystemLib = import ./lib/mkSystem.nix { inherit inputs mkPkgsWithSystem; };
    in
    {
      # accessible via `nix build .#<name>`
      packages = builtins.listToAttrs (
        map (system: {
          name = system;
          value = import ./pkgs {
            pkgs = mkPkgsWithSystem system;
            inherit inputs;
          };
        }) systems
      );

      nixosConfigurations = {
        # nixos builds
        nix-infra = mkSystemLib.mkNixosSystem "x86_64-linux" "nix-infra";
        nix-ops = mkSystemLib.mkNixosSystem "x86_64-linux" "nix-ops";
      };

      darwinConfigurations = {
        # darwin builds
        soulwhisper-mba = mkSystemLib.mkDarwinSystem "aarch64-darwin" "soulwhisper-mba";
      };

      # Convenience output that aggregates the outputs for home, nixos.
      # Also used in ci to build targets generally.
      ciSystems =
        let
          nixos = inputs.nixpkgs.lib.genAttrs (builtins.attrNames inputs.self.nixosConfigurations) (
            attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel
          );
          darwin = inputs.nixpkgs.lib.genAttrs (builtins.attrNames inputs.self.darwinConfigurations) (
            attr: inputs.self.darwinConfigurations.${attr}.system
          );
        in
        nixos // darwin;
    };
}
