# fetch pre-built binaries from github release
{
  pkgs,
  lib,
  fetchurl,
  stdenv,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  if isDarwin then packageData = sourceData.kubectl-mayastor-aarch64-darwin else packageData = kubectl-mayastor-x86_64-linux;
in
stdenv.mkDerivation rec {
  inherit (packageData) pname version src;

  unpackCmd = "tar -xvzf $src";
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -m755 -D kubectl-mayastor $out/bin/kubectl-mayastor
    runHook postInstall

    cat <<EOF >$out/bin/kubectl_complete-mayastor
    #!/usr/bin/env sh
    kubectl mayastor __complete "\$@"
    EOF
    chmod u+x $out/bin/kubectl_complete-mayastor
  '';

  meta = with lib; {
    mainProgram = "kubectl-mayastor";
    platforms = platforms.linux ++ platforms.darwin;
    description = "A kubectl plugin for openebs mayastor";
    homepage = "https://github.com/openebs/mayastor-extensions";
    changelog = "https://github.com/openebs/mayastor-extensions/releases/tag/v${version}";
  };
}