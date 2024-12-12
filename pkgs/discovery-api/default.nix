{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.discovery-api;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.discovery-api;

  doCheck = false;

  ldflags = ["-s" "-w"];

  postInstall = ''
    mv ./_out/discovery-service-linux-* $out/bin/discovery-api
    chmod +x $out/bin/discovery-api
  '';

  meta = {
    mainProgram = "discovery-api";
    description = "Discovery Service provides cluster membership and KubeSpan peer information for Talos Linux clusters.";
    homepage = "https://github.com/siderolabs/discovery-service";
    changelog = "https://github.com/siderolabs/discovery-service/releases/tag/v${version}";
  };
}