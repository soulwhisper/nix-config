{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  vendorHash = lib.importJSON ../vendorhash.json;
  packageData = sourceData.example-app;
in
  pkgs.rustPlatform.buildRustPackage rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    cargoHash = vendorHash.example-app;
    useFetchCargoVendor = true;

    nativeBuildInputs = [pkgs.protobuf];

    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.Security
      pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    ];

    doCheck = false;

    meta = {
      homepage = "https://github.com/user/repo";
      description = "description";
      changelog = "https://github.com/user/repo/releases/tag/${packageData.version}";
      mainProgram = "appname";
    };
  }
