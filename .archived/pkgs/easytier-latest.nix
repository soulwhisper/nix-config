{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  vendorHash = lib.importJSON ../vendorhash.json;
  packageData = sourceData.easytier-latest;
in
  # use latest rust to build this app
  pkgs.unstable.rustPlatform.buildRustPackage rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    cargoHash = vendorHash.easytier-latest;
    useFetchCargoVendor = true;

    nativeBuildInputs = with pkgs; [
      protobuf
      rustPlatform.bindgenHook
    ];

    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.Security
      pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    ];

    doCheck = false; # no tests

    meta = {
      homepage = "https://github.com/EasyTier/EasyTier";
      description = "Simple, decentralized mesh VPN with WireGuard support";
      changelog = "https://github.com/EasyTier/EasyTier/releases/tag/${packageData.version}";
      mainProgram = "easytier-core";
    };
  }
