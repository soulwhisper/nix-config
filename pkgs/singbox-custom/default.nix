{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.singbox-custom;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.buildGoModule rec {
    # this package use go stable
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.singbox-custom;

    subPackages = [
      "cmd/sing-box"
    ];
    tags = [
      "with_quic"
      "with_dhcp"
      "with_wireguard"
      "with_utls"
      "with_acme"
      "with_clash_api"
      "with_gvisor"
      "with_tailscale"
      "with_provider" # custom
      "badlinkname" # custom
      "tfogo_checklinkname0" # custom
    ];

    doCheck = false;

    ldflags = ["-s" "-w"];

    meta = {
      mainProgram = "sing-box";
      description = "Universal proxy platform, with providers support";
      homepage = "https://github.com/CHIZI-0618/sing-box";
      changelog = "https://github.com/CHIZI-0618/sing-box/releases/tag/${packageData.version}";
    };
  }
