# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  inputs,
  pkgs ? import <nixpkgs> {},
  ...
}: {
  caddy-custom = pkgs.callPackage ./caddy-custom {};
  # hass-sgcc = pkgs.callPackage ./hass-sgcc {}; # deprecated, always use container
  kubecolor-catppuccin = pkgs.callPackage ./kubecolor-catppuccin {};
  kubectl-pgo = pkgs.callPackage ./kubectl-pgo {};
  talhelper = inputs.talhelper.packages.${pkgs.system}.default;
  talosctl = pkgs.callPackage ./talosctl {};{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  vendorData = lib.importJSON ../vendorhash.json;

  caddy-version = lib.strings.removePrefix "v" sourceData.caddy-core.version;
  caddy-plugin-cloudflare-version = sourceData.caddy-plugin-cloudflare.version;
in
  # use latest golang to build plugins
  pkgs.unstable.buildGoModule {
    pname = "caddy-custom";
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

  talos-api = pkgs.callPackage ./talos-api {};
  zotregistry = pkgs.callPackage ./zotregistry {};
}
