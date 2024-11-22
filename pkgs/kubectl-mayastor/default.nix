# this one is too complicated to build, so fetch as unfree/proprietary binary;
# https://nixos.wiki/wiki/Packaging/Binaries
# use fixed versions, until wrapper finished
{
  pkgs,
  lib,
  fetchurl,
  stdenv,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
stdenv.mkDerivation rec {
  pname = "kubectl-mayastor";
  version = "v2.7.1";

  src = if isDarwin then
    fetchurl {
      url = "https://github.com/openebs/mayastor-extensions/releases/download/${version}/kubectl-mayastor-aarch64-apple-darwin.tar.gz";
      hash = "sha256-4w/UYMmRwPmjlK8ktO6qnjPolSk0p/fFkSFk5Yp7uJg=";
    }
  else
    fetchurl {
      url = "https://github.com/openebs/mayastor-extensions/releases/download/${version}/kubectl-mayastor-x86_64-linux-musl.tar.gz";
      hash = "sha256-kWWajtIwIXuW64FUcbY7d8So2+BvgT14Dc+QLt2gRnY=";
    };

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