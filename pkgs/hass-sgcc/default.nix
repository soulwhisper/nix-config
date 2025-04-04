{
  pkgs,
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.hass-sgcc;
  vendorData = lib.importJSON ../vendorhash.json;

  python = python3.withPackages (
    ps:
      with ps; [
        onnxruntime
        pillow
        python-dateutil
        python-dotenv
        numpy
        requests
        schedule
        selenium
        sympy
        undetected-chromedriver
      ]
  );
  binPath = lib.makeBinPath [
    pkgs.chromium
  ];
in
  stdenvNoCC.mkDerivation {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.hass-sgcc;

    dontBuild = true;
    doCheck = true;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share
      cp -r scripts $out/share/hass-sgcc

      # src is designed for container, needs to replace '/usr/bin/' and '/data/'
      substituteInPlace $out/share/hass-sgcc/data_fetcher.py --replace-fail "/usr/bin/chromedriver" "${lib.getExe pkgs.undetected-chromedriver}"
      substituteInPlace $out/share/hass-sgcc/main.py --replace-fail "/data/" "./"
      substituteInPlace $out/share/hass-sgcc/data_fetcher.py --replace-fail "/data/" "./"

      makeWrapper ${python.interpreter} "$out/bin/sgcc_fetcher" \
          --add-flags "$out/share/hass-sgcc/main.py" \
          --prefix PATH : "${binPath}"

      runHook postInstall
    '';

    meta = {
      mainProgram = "sgcc_fetcher";
      description = "HomeAssistant sgcc_electricity data fetcher";
      homepage = "https://github.com/ARC-MX/sgcc_electricity_new";
      changelog = "https://github.com/project-zot/zot/releases/tag/v${version}";
    };
  }
