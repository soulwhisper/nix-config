{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.kubectl-browse-pvc;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.unstable.buildGoModule rec {
    inherit (packageData) pname;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.kubectl-browse-pvc;

    src = "${packageData.src}/src";

    ldflags = ["-s" "-w"];

    doCheck = false;

    postInstall = ''
      mv $out/bin/kubectl-browse-pvc $out/bin/kubectl-browse_pvc
    '';

    meta = {
      mainProgram = "kubectl-browse-pvc";
      description = "Kubernetes CLI plugin for browsing PVCs on the command line";
      homepage = "https://github.com/clbx/kubectl-browse-pvc";
      changelog = "https://github.com/clbx/kubectl-browse-pvc/releases/tag/v${version}";
    };
  }
