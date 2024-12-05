{
  lib,
  pkgs,
  stdenv,
  ...
}:
let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  caddyPluginCloudflare = sourceData.caddy-plugin-cloudflare;
  vendorData = lib.importJSON ../_sources/vendorhash.json;
in
stdenv.mkDerivation {
  pname = "caddy";
  version = "latest";
  dontUnpack = true;

  nativeBuildInputs = [ go xcaddy ];

  configurePhase = ''
      export GOCACHE=$TMPDIR/go-cache
      export GOPATH="$TMPDIR/go"
  '';

  buildPhase = ''
    runHook preBuild
    ${pkgs.xcaddy}/bin/xcaddy build latest --with github.com/caddy-dns/cloudflare=${caddyPluginCloudflare}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    mv caddy $out/bin
    runHook postInstall
  '';
}
