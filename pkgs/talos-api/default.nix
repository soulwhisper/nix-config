{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.talos-api;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.buildGoModule rec {
    # this package use go stable
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.talos-api;

    doCheck = false;

    ldflags = ["-s" "-w"];

    postInstall = ''
      mv $out/bin/discovery-service $out/bin/talos-api
    '';

    meta = {
      mainProgram = "talos-api";
      description = "Discovery Service provides cluster membership and KubeSpan peer information for Talos Linux clusters.";
      homepage = "https://github.com/siderolabs/discovery-service";
      changelog = "https://github.com/siderolabs/discovery-service/releases/tag/${packageData.version}";
    };
  }
