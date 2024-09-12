{
  description = "soulwhisper Nix Flake";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust toolchain overlay
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
    };

    # VSCode community extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin
    catppuccin = {
      url = "github:catppuccin/nix/v1.0.1";
    };

    # Nix Inspect
    nix-inspect = {
      url = "github:bluskript/nix-inspect";
    };

    # Talhelper - A tool to help creating Talos Kubernetes cluster
    # https://github.com/budimanjojo/talhelper
    talhelper = {
      url = "github:budimanjojo/talhelper";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    nix-darwin,
    nix-inspect,
    nixvim,
    nix-vscode-extensions,
    sops-nix,
    talhelper,
    ...
  } @inputs:
  let
    supportedSystems = ["x86_64-linux" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    overlays = import ./overlays {inherit inputs;};
    mkSystemLib = import ./lib/mkSystem.nix {inherit inputs overlays;};
    flake-packages = self.packages;

    legacyPackages = forAllSystems (
      system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config.allowUnfree = true;
        }
    );
  in
  {
    inherit overlays;

    packages = forAllSystems (
      system: let
        pkgs = legacyPackages.${system};
      in
        import ./pkgs {
          inherit pkgs;
          inherit inputs;
        }
    );

    nixosConfigurations = {
      nix-vm = mkSystemLib.mkNixosSystem "x86_64-linux" "nix-vm" flake-packages;
      nix-nas = mkSystemLib.mkNixosSystem "x86_64-linux" "nix-nas" flake-packages;
    };

    darwinConfigurations = {
      soulwhisper-mba = mkSystemLib.mkDarwinSystem "aarch64-darwin" "soulwhisper-mba" flake-packages;
    };

    # Convenience output that aggregates the outputs for home, nixos.
    # Also used in ci to build targets generally.
    ciSystems =
      let
        nixos = nixpkgs.lib.genAttrs
          (builtins.attrNames inputs.self.nixosConfigurations)
          (attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel);
        darwin = nixpkgs.lib.genAttrs
          (builtins.attrNames inputs.self.darwinConfigurations)
          (attr: inputs.self.darwinConfigurations.${attr}.system);
      in
        nixos // darwin;
  };
}
