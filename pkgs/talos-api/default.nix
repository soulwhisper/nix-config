{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.talos-api;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.talos-api;

  doCheck = false;

  ldflags = ["-s" "-w"];

  meta = {
    mainProgram = "talos-api";
    description = "Discovery Service provides cluster membership and KubeSpan peer information for Talos Linux clusters.";
    homepage = "https://github.com/siderolabs/discovery-service";
    changelog = "https://github.com/siderolabs/discovery-service/releases/tag/v${version}";
  };
}