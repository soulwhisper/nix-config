{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.singbox-custom;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.unstable.buildGoModule rec {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.singbox-custom;

    subPackages = [
      "cmd/sing-box"
    ];
    tags = [
      "with_quic"
      "with_dhcp"
      "with_utls"
      # "with_acme"
      "with_clash_api"
      "with_gvisor"
      # "with_tailscale"
      "with_provider" # custom
      "badlinkname"
      "tfogo_checklinkname0"
    ];

    doCheck = false;

    ldflags = [
      "-X=github.com/sagernet/sing-box/constant.Version=${lib.strings.removePrefix "v" packageData.version}"
      "-checklinkname=0" # fix https://github.com/SagerNet/sing-box/issues/3374
      "-s"
      "-w"
    ];

    meta = {
      mainProgram = "sing-box";
      description = "Universal proxy platform, with providers support";
      homepage = "https://github.com/CHIZI-0618/sing-box";
      changelog = "https://github.com/CHIZI-0618/sing-box/releases/tag/${packageData.version}";
    };
  }
