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
  packageData = sourceData.usage;
  vendorData = lib.importJSON ../vendorhash.json;
in
rustPlatform.buildRustPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  cargoHash = vendorData.usage;

  passthru = {
    updateScript = nix-update-script { };
  };

  doCheck = false;

  meta = {
    mainProgram = "usage";
    description = "A specification for CLIs";
    homepage = "https://usage.jdx.dev";
    changelog = "https://github.com/jdx/usage/releases/tag/v${version}";
  };
}