{
  pkgs,
  lib,
  installShellFiles,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.zotregistry;
  vendorData = lib.importJSON ../vendorhash.json;

  zotregistry-ui = pkgs.buildNpmPackage rec {
    inherit (sourceData.zotregistry-ui) pname src version;
    npmDepsHash = "sha256-5f9D+DmX4I14wx5mNScero1xWQRtuLwhfDXfHM0mbB4=";

    npmFlags = [ "--legacy-peer-deps" ];

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
  };