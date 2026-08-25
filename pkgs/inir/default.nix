{
  pkgs,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.inir;
  # iNiR ships its own nix packaging (nix/package.nix takes `{ pkgs }` and
  # degrades gracefully on stable nixpkgs via hasAttr guards)
  inirPackage = pkgs.callPackage "${packageData.src}/nix/package.nix" { };
in
inirPackage.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    # source tree + module paths for consumers (environments/niri.nix)
    inherit (packageData) src;
    nixosModule = "${packageData.src}/nix/nixos-module.nix";
  };
})
