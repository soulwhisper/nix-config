{
  pkgs,
  lib,
  installShellFiles,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.zotregistry;
  vendorData = lib.importJSON ../vendorhash.json;

  uiData = sourceData.zotregistry-ui;
in
  pkgs.unstable.buildGoModule rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.zotregistry;

    # proxyVendor = true;

    nativeBuildInputs = [installShellFiles];

    subPackages = [
      "cmd/zli"
      "cmd/zot"
    ];

    preBuild = ''
      tar xvzf ${uiData.src} -C pkg/extensions/
    '';

    tags = [
      "imagetrust,lint,metrics,mgmt,profile,scrub,search,sync,ui,userprefs,containers_image_openpgp"
    ];

    ldflags = [
      "-X zotregistry.dev/zot/pkg/api/config.Commit=v${version}"
      "-X zotregistry.dev/zot/pkg/api/config.BinaryType=-imagetrust-lint-metrics-mgmt-profile-scrub-search-sync-ui-userprefs"
      "-X zotregistry.dev/zot/pkg/api/config.GoVersion=${lib.getVersion go}"
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

    # defaultPlatform = linux-amd64
    meta = {
      mainProgram = "zot";
      description = "A scale-out production-ready vendor-neutral OCI-native container image/artifact registry.";
      homepage = "https://github.com/project-zot/zot";
      changelog = "https://github.com/project-zot/zot/releases/tag/v${version}";
    };
  }
