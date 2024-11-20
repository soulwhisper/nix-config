{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.kubectl-get-all;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.kubectl-get-all;

  doCheck = false;

  tags = [
    "getall"
    "netgo"
  ];

  postInstall = ''
    mv $out/bin/ketall $out/bin/kubectl-get_all

    cat <<EOF >$out/bin/kubectl_complete-get_all
    #!/usr/bin/env sh
    kubectl get-all __complete "\$@"
    EOF
    chmod u+x $out/bin/kubectl_complete-get_all
  '';

  meta = {
    description = "Kubernetes CLI plugin to really get all resources";
    mainProgram = "kubectl-get-all";
    homepage = "https://github.com/corneliusweig/ketall";
    changelog = "https://github.com/corneliusweig/ketall/releases/tag/v${version}";
  };
}