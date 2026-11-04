{
  lib,
  stdenvNoCC,
  makeWrapper,
  forgejo,
  gnupg,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "corp-forgejo";
  inherit (forgejo) version;
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    makeWrapper ${lib.getExe forgejo} "$out/bin/forgejo" \
      --add-flags '--work-path=/var/lib/forgejo --custom-path=/var/lib/forgejo/custom --config=/var/lib/forgejo/custom/conf/app.ini' \
      --set-default HOME /var/lib/forgejo \
      --set-default USER appuser \
      --set-default FORGEJO_WORK_DIR /var/lib/forgejo \
      --set-default FORGEJO_CUSTOM /var/lib/forgejo/custom \
      --prefix PATH : ${lib.makeBinPath [ gnupg ]}
    ln -s ${forgejo}/bin/environment-to-ini "$out/bin/environment-to-ini"
    runHook postInstall
  '';

  passthru.data = forgejo.data;
  meta = {
    inherit (forgejo.meta)
      homepage
      license
      platforms
      broken
      ;
    description = "Official Forgejo with corporate service paths and runtime dependencies";
    mainProgram = "forgejo";
  };
}
