{
  pkgs,
  lib,
  installShellFiles,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix { };
  vendorData = lib.importJSON ../vendorhash.json;

  caddy-version =  lib.strings.removePrefix "v" sourceData.caddy-core.version;
  caddy-plugin-cloudflare-version = sourceData.caddy-plugin-cloudflare.version;
in
# use latest golang to build plugins
pkgs.unstable.buildGoModule {
  pname = "caddy-cloudflare";
  version = caddy-version + "-cloudflare-" + caddy-plugin-cloudflare-version;

  src = ./src;

  runVend = true;
  vendorHash = vendorData.caddy-custom;

  ldflags = ["-s" "-w"];

  meta = with lib; {
    homepage = "https://caddyserver.com";
    description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
    license = licenses.asl20;
    mainProgram = "caddy";
  };
}