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

    # fix: module lookup disabled by GOPROXY=off
    # proxyVendor = true;

    configurePhase = ''
      export GOCACHE="$TMPDIR/go-cache"
      export GOPATH="$TMPDIR/go"
      export GOPROXY="https://goproxy.cn,direct"
    '';

    postPatch = ''
      substituteInPlace go.mod \
        --replace-fail "cel.dev/expr" "github.com/google/cel-spec"
      substituteInPlace go.mod \
        --replace-fail "cloud.google.com/go" "github.com/googleapis/google-cloud-go"
      substituteInPlace go.mod \
        --replace-fail "cuelabs.dev/go/oci/ociregistry" "github.com/cue-labs/oci"
      substituteInPlace go.mod \
        --replace-fail "cuelang.org/go" "github.com/cue-lang/cue"
      substituteInPlace go.mod \
        --replace-fail "dario.cat/mergo" "github.com/imdario/mergo"
      substituteInPlace go.mod \
        --replace-fail "filippo.io/edwards25519" "github.com/FiloSottile/edwards25519"
      substituteInPlace Makefile \
        --replace-fail "$(shell which stacker)" ""
    '';

    nativeBuildInputs = with pkgs; [
      git
      nodejs
    ];

    # default = linux-amd64
    buildPhase = ''
      make OS=linux ARCH=amd64 binary cli
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
