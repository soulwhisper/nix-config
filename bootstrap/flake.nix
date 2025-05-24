{
  description = "Bootstrap flake for nixos";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Disko - declarative disk partitioning and formatting
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    disko,
    nixpkgs,
  }: {
    nixosConfigurations.nixos = nixpkgs.legacyPackages.x86_64-linux.nixos [
      ./configuration.nix
      disko.nixosModules.disko
    ];
  };
}
