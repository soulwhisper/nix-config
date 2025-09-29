{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.mosdns-custom;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.buildGoModule rec {
    # this package use go stable
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.mosdns-custom;

    doCheck = false;

    ldflags = ["-s" "-w"];

    meta = {
      mainProgram = "mosdns-custom";
      description = "Modular, pluggable DNS forwarder, with `domain_output` plugin.";
      homepage = "https://github.com/yyysuo/mosdns";
      changelog = "https://github.com/yyysuo/mosdns/releases/tag/${packageData.version}";
    };
  }
