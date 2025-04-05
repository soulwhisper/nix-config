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
      # patch hardcoded path
      substituteInPlace scripts/data_fetcher.py --replace-warn "./captcha.onnx" "$out/lib/captcha.onnx"
      substituteInPlace scripts/onnx.py --replace-warn "./captcha.onnx" "$out/lib/captcha.onnx"
      substituteInPlace scripts/onnx.py --replace-warn "../assets/" "$out/share/assets/"
      # patch hardcoded workdir
      substituteInPlace scripts/data_fetcher.py --replace-warn "/usr/bin/chromedriver" "/tmp/chromedriver"
      substituteInPlace scripts/data_fetcher.py --replace-warn "/data/" ""
      substituteInPlace scripts/main.py --replace-warn "/data/" ""
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"/{bin,share/assets,share/bin}
      cp -r scripts $out/lib
      cp assets/background.png $out/share/assets/

      makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/sgcc_fetcher \
        --add-flags "$out/lib/main.py" \
        --prefix PATH : ${lib.makeBinPath [pkgs.chromium]} \
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
