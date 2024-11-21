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
  packageData = sourceData.mayastor;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
rustPlatform.buildRustPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  cargoHash = vendorData.mayastor;

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
    homepage = "https://github.com/openebs/mayastor-extensions";
    changelog = "https://github.com/openebs/mayastor-extensions/releases/tag/v${version}";
  };
}