{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  openssl,
  age,
  sops,
}:
stdenvNoCC.mkDerivation {
  pname = "root-ca";
  version = "1.0.0";
  src = ./.;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  nativeCheckInputs = [
    python3
    openssl
    age
  ];
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python3 -m unittest discover -s . -p 'test_*.py' -v
    runHook postCheck
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 root_ca.py "$out/libexec/root-ca"
    makeWrapper ${python3}/bin/python3 "$out/bin/root-ca" \
      --add-flags "$out/libexec/root-ca" \
      --prefix PATH : ${
        lib.makeBinPath [
          openssl
          age
          sops
        ]
      }
    runHook postInstall
  '';
  meta = {
    description = "Offline, transactional OpenSSL root authority lifecycle manager";
    mainProgram = "root-ca";
    platforms = lib.platforms.unix;
  };
}
