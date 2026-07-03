{
  inputs,
  mkPkgsWithSystem,
  ...
}:
{
  mkNixosSystem =
    system: hostname:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      pkgs = mkPkgsWithSystem system;
      modules = [
        {
          nixpkgs.hostPlatform = system;
          _module.args = {
            inherit inputs system;
          };
        }
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        {
          home-manager = {
            # useGlobalPkgs = true: HM reuses the system-level nixpkgs (which
            # includes the unstable overlay).  Individual home.packages can
            # therefore reference `pkgs.unstable.<pkg>` directly.
            # Trade-off: tight coupling — a home-only package that needs unstable
            # would require the overlay here; a per-user import would be looser.
            useUserPackages = true;
            useGlobalPkgs = true;
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.catppuccin.homeModules.catppuccin
            ];
            extraSpecialArgs = {
              inherit inputs hostname system;
            };
            users.soulwhisper = ../. + "/homes/soulwhisper";
          };
        }
        ../hosts/_modules/common
        ../hosts/_modules/nixos
        ../hosts/${hostname}
      ];
      specialArgs = {
        inherit inputs hostname;
      };
    };

  mkDarwinSystem =
    system: hostname:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      pkgs = mkPkgsWithSystem system;
      modules = [
        {
          nixpkgs.hostPlatform = system;
          _module.args = {
            inherit inputs;
          };
        }
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            # useGlobalPkgs = true: HM reuses the system-level nixpkgs (which
            # includes the unstable overlay).  Individual home.packages can
            # therefore reference `pkgs.unstable.<pkg>` directly.
            # Trade-off: tight coupling — a home-only package that needs unstable
            # would require the overlay here; a per-user import would be looser.
            useUserPackages = true;
            useGlobalPkgs = true;
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.catppuccin.homeModules.catppuccin
            ];
            extraSpecialArgs = {
              inherit inputs hostname system;
            };
            users.soulwhisper = ../. + "/homes/soulwhisper";
          };
        }
        ../hosts/_modules/common
        ../hosts/_modules/darwin
        ../hosts/${hostname}
      ];
      specialArgs = {
        inherit inputs hostname;
      };
    };
}
