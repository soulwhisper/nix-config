{
  lib,
  pkgs,
  stdenv,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  caddyCore = sourceData.caddy-core;
  caddyPluginCloudflare = sourceData.caddy-plugin-cloudflare;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
stdenv.mkDerivation {
  pname = "caddy";
  version = "${caddyCore.version}";
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.go pkgs.xcaddy ];

  configurePhase = ''
      export GOCACHE=$TMPDIR/go-cache
      export GOPATH="$TMPDIR/go"
  '';

  buildPhase = ''
    runHook preBuild
    XCADDY_SKIP_BUILD=1 TMPDIR="$PWD" ${pkgs.xcaddy}/bin/xcaddy build ${caddyCore.version} \
      --with github.com/caddyserver/caddy/v2@${caddyCore.version}=${caddyCore.src}
      --with github.com/caddy-dns/cloudflare=${caddyPluginCloudflare.src}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mv buildenv* $out
    runHook postInstall
  '';

  meta.mainProgram = "caddy";
}
