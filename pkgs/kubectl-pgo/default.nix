{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.kubectl-pgo;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.kubectl-pgo;

  ldflags = ["-s" "-w"];

  doCheck = false;

  meta = {
    mainProgram = "kubectl-pgo";
    description = "Kubernetes CLI plugin to manage Crunchy PostgreSQL Operator resources.";
    homepage = "https://github.com/CrunchyData/postgres-operator-client";
    changelog = "https://github.com/CrunchyData/postgres-operator-client/releases/tag/v${version}";
  };
}