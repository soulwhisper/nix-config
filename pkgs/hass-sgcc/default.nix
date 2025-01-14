{
  pkgs,
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.hass-sgcc;
  vendorData = lib.importJSON ../vendorhash.json;

  python = python3.withPackages (
    ps: with ps; [
      onnxruntime
      pillow
      numpy
      requests
      selenium
      schedule
      undetected_chromedriver
    ]
  );
in
stdenvNoCC.mkDerivation {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.hass-sgcc;

  dontBuild = true;
  doCheck = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/hass-sgcc
    cp -r scripts $out/share/hass-sgcc

    makeWrapper ${python.interpreter} "$out/bin/sgcc_fetcher" \
        --add-flags "$out/share/hass-sgcc/main.py"

    runHook postInstall
  '';

  meta = with lib; {
    mainProgram = "sgcc_fetcher";
    description = "HomeAssistant sgcc_electricity data fetcher";
    homepage = "https://github.com/ARC-MX/sgcc_electricity_new";
    maintainers = with maintainers; [soulwhisper];
  };
}