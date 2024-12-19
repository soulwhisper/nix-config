{
  pkgs,
  lib,
  python39Packages,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.hass-sgcc;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
python39Packages.buildPythonPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.hass-sgcc;

  nativeBuildInputs = [
    python39Packages.setuptools
    pkgs.chromium
    pkgs.chromedriver
  ];

  projectfile = ./patches;

  preBuild = ''
    cp ${projectfile}/setup.py .
    sed -i -E "s/version='VERSION'/version='${version}'/" ./setup.py
  '';

  meta = with lib; {
    mainProgram = "sgcc_fetcher";
    description = "HomeAssistant sgcc_electricity data fetcher";
    homepage = "https://github.com/ARC-MX/sgcc_electricity_new";
    maintainers = with maintainers; [soulwhisper];
  };
}