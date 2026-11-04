{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  openssh,
  openssl,
  git,
  nix,
  nvd,
  age,
  sops,
}:
let
  python = python3.withPackages (ps: [
    ps.cryptography
    ps.pyyaml
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "corp-deployment-tools";
  version = "1.0.0";
  src = ./.;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  doCheck = true;
  nativeCheckInputs = [
    python
    age
    sops
    openssl
    git
  ];
  checkPhase = ''
    runHook preCheck
    export HOME="$TMPDIR/deployment-tests-home"
    mkdir -m700 "$HOME"
    export GIT_CONFIG_NOSYSTEM=1
    ${python}/bin/python ./tests.py
    runHook postCheck
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/deployment-tools" "$out/bin"
    cp controller.py "$out/lib/deployment-tools/controller.py"
    for command in deploymentctl pki-admin forgejo-admin; do
      makeWrapper ${python}/bin/python "$out/bin/$command" \
        --add-flags "$out/lib/deployment-tools/controller.py $command" \
        --prefix PATH : ${
          lib.makeBinPath [
            openssh
            openssl
            git
            nix
            nvd
            age
            sops
          ]
        }
    done
    runHook postInstall
  '';
  passthru = { inherit python; };
  meta = {
    description = "Explicit, pinned NixOS deployment and offline PKI controller tools";
    platforms = lib.platforms.unix;
    mainProgram = "deploymentctl";
    license = lib.licenses.mit;
  };
}
