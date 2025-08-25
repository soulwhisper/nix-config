{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.sillytavern;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.unstable.buildNpmPackage rec {
    inherit (packageData) pname;
    version = lib.strings.removePrefix "v" packageData.version;
    npmDepsHash = vendorData.sillytavern;

    src = "${packageData.src}/src";

    nativeBuildInputs = [pkgs.makeBinaryWrapper];

    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,opt}
      cp -r . $out/opt/sillytavern
      makeWrapper ${pkgs.unstable.nodejs}/bin/node $out/bin/sillytavern \
        --add-flags $out/opt/sillytavern/server.js \
        --set-default NODE_ENV production

      runHook postInstall
    '';

    meta = {
      mainProgram = "sillytavern";
      description = "LLM Frontend for Power Users";
      homepage = "https://docs.sillytavern.app";
      changelog = "https://github.com/SillyTavern/SillyTavern/releases/tag/${packageData.version}";
    };
  }
