{
  pkgs,
  lib,
  rustPlatform,
  nix-update-script,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (pkgs.darwin.apple_sdk.frameworks) Security SystemConfiguration;

  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.kubectl-mayastor;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
rustPlatform.buildRustPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  cargoHash = vendorData.kubectl-mayastor;

  passthru = {
    updateScript = nix-update-script { };
  };

  postInstall = ''
    cat <<EOF >$out/bin/kubectl_complete-mayastor
    #!/usr/bin/env sh
    kubectl mayastor __complete "\$@"
    EOF
    chmod u+x $out/bin/kubectl_complete-mayastor
  '';

  doCheck = false;

  meta = {
    mainProgram = "kubectl-mayastor";
    description = "A kubectl plugin for OpenEBS Mayastor";
    homepage = "https://github.com/openebs/mayastor";
    changelog = "https://github.com/openebs/mayastor/releases/tag/v${version}";
  };
}