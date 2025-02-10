{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  vendorHash = lib.importJSON ../vendorhash.json;
  packageData = sourceData.easytier-custom;
in
  pkgs.rustPlatform.buildRustPackage rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    cargoHash = vendorHash.easytier-custom;
    useFetchCargoVendor = true;

    nativeBuildInputs = [pkgs.protobuf];

    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.Security
      pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    ];

    doCheck = false; # no tests

    meta = {
      homepage = "https://github.com/EasyTier/EasyTier";
      description = "Simple, decentralized mesh VPN with WireGuard support";
      changelog = "https://github.com/EasyTier/EasyTier/releases/tag/v${version}";
      mainProgram = "easytier-core";
    };
  }
