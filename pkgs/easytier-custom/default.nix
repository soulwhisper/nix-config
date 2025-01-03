{
  pkgs,
  lib,
  rustPlatform,
  nix-update-script,
  protobuf,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (pkgs.darwin.apple_sdk.frameworks) Security SystemConfiguration;

  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.easytier-custom;
  vendorData = lib.importJSON ../vendorhash.json;
in
rustPlatform.buildRustPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  cargoHash = vendorData.easytier-custom;
  useFetchCargoVendor = true;

  nativeBuildInputs = [ protobuf ];

  passthru = {
    updateScript = nix-update-script { };
  };

  doCheck = false;

  meta = {
    homepage = "https://github.com/EasyTier/EasyTier";
    changelog = "https://github.com/EasyTier/EasyTier/releases/tag/v${version}";
    description = "Simple, decentralized mesh VPN with WireGuard support";
    mainProgram = "easytier-core";
  };
}