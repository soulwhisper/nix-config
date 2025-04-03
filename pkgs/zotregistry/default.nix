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
in
  pkgs.unstable.buildGoModule rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.zotregistry;

    nativeBuildInputs = [installShellFiles];

    subPackages = [
      "cmd/zli"
      "cmd/zot"
    ];

    preBuild = ''
      ln -s ${zotregistry-ui}/build pkg/extensions/build
    '';

    tags = [
      "imagetrust,lint,metrics,mgmt,profile,scrub,search,sync,ui,userprefs,containers_image_openpgp"
    ];

    ldflags = [
      "-X zotregistry.dev/zot/pkg/api/config.Commit=v${version}"
      "-X zotregistry.dev/zot/pkg/api/config.BinaryType=-imagetrust-lint-metrics-mgmt-profile-scrub-search-sync-ui-userprefs"
      "-X zotregistry.dev/zot/pkg/api/config.GoVersion=${lib.getVersion pkgs.unstable.go}"
      "-s"
      "-w"
    ];

    doCheck = false;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/zli-* -t $out/bin/zli
      install -Dm755 bin/zot-* -t $out/bin/zot
      runHook postInstall
    '';

    postInstall = ''
      installShellCompletion --cmd zli \
        --bash <($out/bin/zli completion bash) \
        --fish <($out/bin/zli completion fish) \
        --zsh <($out/bin/zli completion zsh)
    '';

    meta = {
      mainProgram = "zot";
      description = "A scale-out production-ready vendor-neutral OCI-native container image/artifact registry.";
      homepage = "https://github.com/project-zot/zot";
      changelog = "https://github.com/project-zot/zot/releases/tag/v${version}";
    };
  }
