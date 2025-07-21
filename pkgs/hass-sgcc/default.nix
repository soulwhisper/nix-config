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

    # https://github.com/ARC-MX/sgcc_electricity_new/blob/master/requirements.txt
    pythonPath = with pkgs.python3Packages; [
      onnxruntime
      pillow
      python-dotenv
      numpy
      requests
      schedule
      selenium
      sympy
      webdriver-manager
    ];

    format = "other";
    dontBuild = true;
    doCheck = false;

    postPatch = ''
      # patch hardcoded path
      substituteInPlace scripts/data_fetcher.py --replace-warn "./captcha.onnx" "$out/lib/captcha.onnx"
      substituteInPlace scripts/onnx.py --replace-warn "./captcha.onnx" "$out/lib/captcha.onnx"
      substituteInPlace scripts/onnx.py --replace-warn "../assets/" "$out/lib/"
      # patch hardcoded workdir
      substituteInPlace scripts/data_fetcher.py --replace-warn "/usr/bin/geckodriver" "/tmp/geckodriver"
      substituteInPlace scripts/data_fetcher.py --replace-warn "/data/" ""
      substituteInPlace scripts/main.py --replace-warn "/data/" ""
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -r scripts $out/lib
      cp assets/background.png $out/lib/

      makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/sgcc_fetcher \
        --add-flags "$out/lib/main.py" \
        --prefix PATH : ${lib.makeBinPath [pkgs.firefox-esr pkgs.geckodriver]} \
        --prefix PYTHONPATH : "$PYTHONPATH"

      runHook postInstall
    '';

    meta = {
      mainProgram = "sgcc_fetcher";
      description = "Home-assistant sgcc_electricity data fetcher";
      homepage = "https://github.com/ARC-MX/sgcc_electricity_new";
      changelog = "https://github.com/ARC-MX/sgcc_electricity_new/tag/${packageData.version}";
    };
  }
