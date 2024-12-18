{
  pkgs,
  lib,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.hass-sgcc;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
buildPythonPackage rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.hass-sgcc;

  nativeBuildInputs = with pkgs; [
    python39Packages.pip
    python39Packages.setuptools
    python39Packages.wheel
    pkgs.chromium
    pkgs.chromiumDriver
  ];

  preBuild = ''
    python3 -m pip install --upgrade pip
    PIP_ROOT_USER_ACTION=ignore pip install --disable-pip-version-check --no-cache-dir -r requirements.txt
  '';

  meta = with lib; {
    description = "HomeAssistant sgcc_electricity";
    homepage = "https://github.com/ARC-MX/sgcc_electricity_new";
    license = licenses.apache2;
    maintainers = with maintainers; [soulwhisper];
  };
}