{ pkgs, lib, ... }:

let
  sourceData  = pkgs.callPackage ../_sources/generated.nix { };
  packageData = sourceData.isc-stork;
  vendorData  = lib.importJSON ../vendorhash.json;
  webuiSrc = pkgs.runCommand "isc-stork-webui-src" { } ''
    cp -r ${packageData.src}/webui $out
  '';
in
pkgs.buildGoModule rec {
  inherit (packageData) pname src;
  version = lib.strings.removePrefix "v" packageData.version;
  vendorHash = vendorData.isc-stork;

  modRoot    = "backend";

  npmDeps = pkgs.fetchNpmDeps {
    name = "${pname}-npm-deps-${version}";
    src  = webuiSrc;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # hardcoded npmDepsHash for current version
  };

  subPackages = [
    "cmd/stork-server"
    "cmd/stork-agent"
    "cmd/stork-tool"
  ];

  nativeBuildInputs = with pkgs; [
    nodejs_22
    go-swagger
    protobuf
    protoc-gen-go
    protoc-gen-go-grpc
  ];

  ldflags = ["-s" "-w"];

  overrideModAttrs = _: {
    preBuild = "";
  };

  preBuild = ''
    pushd ..

    ##### fronted #####
    pushd webui
    export HOME=$(mktemp -d)
    npm config set cache "$npmDeps"
    npm config set offline true
    npm ci --offline --no-audit --no-fund --ignore-scripts
    npx ng build --configuration production
    popd

    ##### code-gen 1: yamlinc merge swagger fragments #####
    ./webui/node_modules/.bin/yamlinc \
      -o api/swagger.yaml api/swagger.in.yaml

    ##### code-gen 2: go-swagger gen server stubs (stratoscale template) #####
    swagger generate server \
      -m server/gen/models \
      -s server/gen/restapi \
      --exclude-main --name Stork --regenerate-configureapi \
      --spec ../api/swagger.yaml \
      --template stratoscale \
      --target backend
    # upstream fix
    sed -i 's|//go:generate mockery .*||' \
      backend/server/gen/restapi/configure_stork.go

    ##### code-gen 3: protoc gRPC #####
    pushd backend/api
    protoc --proto_path=. --go_out=. --go-grpc_out=. agent.proto
    popd

    ##### code-gen 4: stork-code-gen → DHCP option defs #####
    pushd backend/cmd/stork-code-gen
    go build -o stork-code-gen .
    popd
    for v in 4 6; do
      backend/cmd/stork-code-gen/stork-code-gen std-option-defs \
        --input    codegen/std_dhcpv''${v}_option_def.json \
        --output   backend/daemoncfg/kea/stdoptiondef''${v}.go \
        --template backend/daemoncfg/kea/stdoptiondef''${v}.go.template
    done
    pushd backend && go fmt ./daemoncfg/kea/... && popd

    popd
  '';

  doCheck = false;

  postInstall = ''
    pushd ..

    mkdir -p $out/share/stork/www
    cp -a webui/dist/stork/browser/. $out/share/stork/www/

    install -Dm644 etc/isc-stork-server.service \
      $out/share/stork/systemd/isc-stork-server.service
    install -Dm644 etc/isc-stork-agent.service \
      $out/share/stork/systemd/isc-stork-agent.service
    install -Dm644 etc/server.env $out/share/stork/server.env.example
    install -Dm644 etc/agent.env  $out/share/stork/agent.env.example

    mkdir -p $out/share/stork/examples
    [ -f etc/nginx-stork.conf ] && cp etc/nginx-stork.conf $out/share/stork/examples/
    cp -a grafana $out/share/stork/examples/grafana

    popd
  '';

  meta = with lib; {
    description = "ISC Stork: dashboard for Kea DHCP and BIND 9";
    homepage    = "https://gitlab.isc.org/isc-projects/stork";
    license     = licenses.mpl20;
    platforms   = platforms.linux;
    mainProgram = "stork-server";
  };
}
