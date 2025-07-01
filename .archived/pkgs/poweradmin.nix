{
  pkgs,
  lib,
  ...
}: let
  sourceData = pkgs.callPackage ../_sources/generated.nix {};
  packageData = sourceData.poweradmin;
  vendorData = lib.importJSON ../vendorhash.json;
in
  pkgs.php.buildComposerProject2 (finalAttrs: {
    inherit (packageData) pname src;
    version = lib.strings.removePrefix "v" packageData.version;
    vendorHash = vendorData.poweradmin;

    composerNoDev = true;

    postInstall = ''
      chmod -R u+w $out/share
      mv $out/share/php/poweradmin $out/app
      mv $out/app/install $out/install
      rm -r $out/share
    '';

    meta = {
      description = "A web-based control panel for PowerDNS.";
      homepage = "https://github.com/poweradmin/poweradmin";
      changelog = "https://github.com/poweradmin/poweradmin/releases/tag/${packageData.version}";
    };
  })
