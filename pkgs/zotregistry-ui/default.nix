{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.zotregistry-ui;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.buildNpmPackage rec {
    inherit (packageData) pname src version;
    npmDepsHash = vendorData.zotregistry-ui;

    npmFlags = ["--legacy-peer-deps"];

    installPhase = ''
      runHook preInstall
      cp -r . "$out"
      runHook postInstall
    '';

    meta = with lib; {
      description = "UI for zot registry";
      homepage = "https://github.com/project-zot/zui";
      changelog = "https://github.com/project-zot/zui/releases";
    };
  }
