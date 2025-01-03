{
  pkgs,
  lib,
  installShellFiles,
  ...
}: let
  info = import ./src/info.nix;

  caddy-version =  lib.removePrefix "v" info.version;
  cloudflare-version-string = lib.splitString "-" (lib.removePrefix "v" info.cfVersion);
  cloudflare-version = lib.elemAt cloudflare-version-string 0 + "+" + lib.elemAt cloudflare-version-string 2;
in
# use latest golang to build plugins
pkgs.unstable.buildGoModule {
  pname = "caddy-with-plugins";
  version = caddy-version + "-" + cloudflare-version;

  src = ./src;

  runVend = true;
  inherit (info) vendorHash;

  ldflags = ["-s" "-w"];

  meta = with lib; {
    homepage = "https://caddyserver.com";
    description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
    license = licenses.asl20;
    mainProgram = "caddy";
  };
}