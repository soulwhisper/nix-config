{
  pkgs,
  stdenv,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.rime-moqi-yinxing;
in
  stdenv.mkDerivation {
    inherit (packageData) pname src version;
    installPhase = ''
      mkdir -p $out
      cp -rf . $out
    '';
  }
