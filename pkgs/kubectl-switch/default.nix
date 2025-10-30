{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.kubectl-switch;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.unstable.buildGoModule rec {
    inherit (packageData) pname;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.kubectl-switch;

    src = "${packageData.src}/src";

    ldflags = ["-s" "-w"];

    doCheck = false;

    meta = {
      mainProgram = "kubectl-switch";
      description = "A simple tool to help manage multiple kubeconfig files";
      homepage = "https://github.com/mirceanton/kubectl-switch";
      changelog = "https://github.com/mirceanton/kubectl-switch/releases/tag/${packageData.version}";
    };
  }
