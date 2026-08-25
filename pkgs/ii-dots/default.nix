{
  pkgs,
  stdenv,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.dots-hyprland;
in
stdenv.mkDerivation {
  inherit (packageData) pname src version;
  # scripts carry functional shebangs (e.g. a `env -S sh -c` wrapper that
  # activates ii's python venv at runtime) — patchShebangs must not touch them
  dontPatchShebangs = true;
  # no build steps; pure config copy
  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r dots/.config $out/.config
  '';
}
