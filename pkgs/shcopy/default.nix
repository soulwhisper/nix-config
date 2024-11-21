{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.shcopy;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.shcopy;

  meta = {
    homepage = "https://github.com/aymanbagabas/shcopy";
    description = "Copy text to your system clipboard locally and remotely using ANSI OSC52 sequence";
    changelog = "https://github.com/aymanbagabas/shcopy/releases/tag/v${version}";
    mainProgram = "shcopy";
  };
}