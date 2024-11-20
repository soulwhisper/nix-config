{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.kubectl-mayastor;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.kubectl-mayastor;

  doCheck = false;

  postInstall = ''
    cat <<EOF >$out/bin/kubectl_complete-mayastor
    #!/usr/bin/env sh
    kubectl mayastor __complete "\$@"
    EOF
    chmod u+x $out/bin/kubectl_complete-mayastor
  '';

  meta = {
    description = "A kubectl plugin for OpenEBS Mayastor";
    mainProgram = "kubectl-mayastor";
    homepage = "https://github.com/openebs/mayastor-extensions";
    changelog = "https://github.com/openebs/mayastor-extensions/releases/tag/v${version}";
  };
}