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

  ldflags = ["-s" "-w"];

  meta = {
    mainProgram = "shcopy";
    description = "Copy text to your system clipboard locally and remotely using ANSI OSC52 sequence";
    homepage = "https://github.com/aymanbagabas/shcopy";
    changelog = "https://github.com/aymanbagabas/shcopy/releases/tag/v${version}";
  };
}