{
  pkgs,
  lib,
  python3Packages,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.hass-sgcc;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
python3Packages.buildPythonApplication rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.hass-sgcc;
  pyproject = true;

  # this pkg current is on-halt for dealing .whl runtime;
  # check: https://github.com/NixOS/nixpkgs/issues/366431

  build-system = with python3Packages; [
    hatchling
    hatch-requirements-txt
  ];

  dependencies = with python3Packages; [
    setuptools
    requests
    selenium
    schedule
    pillow
    onnxruntime
    numpy
    python-dotenv
    python-dateutil
    undetected-chromedriver
  ];

  preBuild = ''
    cat << EOF > pyproject.toml
    [build-system]
    requires = ["hatchling", "hatch-requirements-txt"]
    build-backend = "hatchling.build"
    [project]
    name = "sgcc_electricity"
    version = "${version}"
    dynamic = ["dependencies"]
    [tool.hatch.metadata.hooks.requirements_txt]
    files = ["requirements.txt"]
    [tool.hatch.build.targets.wheel]
    packages = ["scripts"]
    EOF
  '';

  doCheck = false;
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    mainProgram = "sgcc_fetcher";
    description = "HomeAssistant sgcc_electricity data fetcher";
    homepage = "https://github.com/ARC-MX/sgcc_electricity_new";
    maintainers = with maintainers; [soulwhisper];
  };
}
