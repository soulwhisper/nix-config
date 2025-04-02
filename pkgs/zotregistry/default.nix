{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.zotregistry;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.unstable.buildGoModule rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.zotregistry;

    # default = linux-amd64
    buildPhase = ''
      runHook preBuild
      make OS=linux ARCH=amd64 binary cli
      runHook postBuild
    '';

    doCheck = false;

    ldflags = ["-s" "-w"];

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/zot-linux-amd64 -t $out/bin/zotregistry
      install -Dm755 bin/zli-linux-amd64 -t $out/bin/zotregistry-cli
      runHook postInstall
    '';

    meta = {
      mainProgram = "zotregistry";
      description = "A scale-out production-ready vendor-neutral OCI-native container image/artifact registry.";
      homepage = "https://github.com/project-zot/zot";
      changelog = "https://github.com/project-zot/zot/releases/tag/v${version}";
    };
  }
