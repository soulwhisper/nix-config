# make sure nvfetcher.toml contains "git.fetchSubmodules = true"
# using rustc version in nix-24.05
{
  pkgs,
  lib,
  openssl,
  nix-update-script,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (pkgs.darwin.apple_sdk.frameworks) Security SystemConfiguration;

  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.stable."1.77.2".minimal;
    rustc = pkgs.rust-bin.stable."1.77.2".minimal;
  };

  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.kubectl-mayastor;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
rustPlatform.buildRustPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  cargoHash = vendorData.kubectl-mayastor;

  buildInputs = [ openssl ];

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