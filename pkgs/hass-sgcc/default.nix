{
  lib,
  pkgs,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.hass-sgcc;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.python3Packages.buildPythonApplication rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.hass-sgcc;

    pythonPath = with pkgs.python3Packages; [
      onnxruntime
      pillow
      python-dotenv
      numpy
      requests
      schedule
      selenium
      sympy
      undetected-chromedriver
    ];

    format = "other";
    dontBuild = true;
    doCheck = false;

    postPatch = ''
      # patch hardcored path
      substituteInPlace scripts/data_fetcher.py --replace-warn "/usr/bin/chromedriver" "undetected-chromedriver"
      substituteInPlace scripts/main.py --replace-warn "../assets/" ""
      # patch hardcored workdir
      substituteInPlace scripts/data_fetcher.py --replace-warn "/data/" "$out/share/data/"
      substituteInPlace scripts/main.py --replace-warn "/data/" "$out/share/data/"
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"/{bin,share/data}
      cp -r scripts $out/share/lib
      cp assets/background.png $out/share/lib/

      makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/sgcc_fetcher \
        --add-flags "$out/share/lib/main.py" \
        --prefix PATH : ${lib.makeBinPath [pkgs.chromium pkgs.undetected-chromedriver]} \
        --prefix PYTHONPATH : "$PYTHONPATH"

      runHook postInstall
    '';

    meta = {
      mainProgram = "sgcc_fetcher";
      description = "HomeAssistant sgcc_electricity data fetcher";
      homepage = "https://github.com/ARC-MX/sgcc_electricity_new";
      changelog = "https://github.com/project-zot/zot/releases/tag/${packageData.version}";
    };
  }
