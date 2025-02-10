{
  pkgs,
  lib,
  rustPlatform,
  protobuf,
  nix-update-script,
  darwin,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  vendorHash = lib.importJSON ../vendorhash.json;
  packageData = sourceData.easytier-custom;
in
rustPlatform.buildRustPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  cargoHash = vendorHash.easytier-custom;

  nativeBuildInputs = [ protobuf ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  doCheck = false; # no tests

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/EasyTier/EasyTier";
    description = "Simple, decentralized mesh VPN with WireGuard support";
    changelog = "https://github.com/EasyTier/EasyTier/releases/tag/v${version}";
    mainProgram = "easytier-core";
  };
}