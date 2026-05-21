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
      pillow
      mysql-connector
      numpy
      openai
      requests
      schedule
      selenium
    ];

    format = "other";
    dontBuild = true;
    doCheck = false;

    postPatch = ''
      # patch hardcoded path
      substituteInPlace scripts/data_fetcher.py \
        --replace-fail '/usr/bin/chromium'     '${pkgs.chromium}/bin/chromium' \
        --replace-fail '/usr/bin/chromedriver' '${pkgs.chromedriver}/bin/chromedriver'
      # patch hardcoded workdir
      substituteInPlace scripts/data_fetcher.py --replace-warn '/data/' ""
      substituteInPlace scripts/main.py         --replace-warn '/data/' ""
      substituteInPlace scripts/db.py           --replace-warn '/data/' ""
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -r scripts $out/lib

      makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/sgcc_fetcher \
        --set PYTHON_IN_DOCKER 1 \
        --add-flags "$out/lib/main.py" \
        --prefix PATH : ${lib.makeBinPath [pkgs.chromium pkgs.chromedriver]} \
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
