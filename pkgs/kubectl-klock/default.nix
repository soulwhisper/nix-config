{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.kubectl-klock;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.kubectl-klock;

  doCheck = false;

  postInstall = ''
    cat <<EOF >$out/bin/kubectl_complete-klock
    #!/usr/bin/env sh
    kubectl klock __complete "\$@"
    EOF
    chmod u+x $out/bin/kubectl_complete-klock
  '';

  meta = {
    mainProgram = "kubectl-klock";
    description = "A kubectl plugin to render watch output in a more readable fashion";
    homepage = "https://github.com/applejag/kubectl-klock";
    changelog = "https://github.com/applejag/kubectl-klock/releases/tag/v${version}";
  };
}