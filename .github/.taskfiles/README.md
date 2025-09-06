## Go-Task

- replaced by justfile

### Usage

```shell
# deps: nix,go-task
curl -L https://nixos.org/nix/install | sh
brew install go-task
nix-shell -p go-task

# : darwin
# :: opt. run set-proxy script
sudo python3 scripts/darwin_set_proxy.py
# :: init, if darwin-rebuild not exist
task darwin:init
# :: build & diff
task darwin:build
# :: switch
task darwin:switch

# : nixos, local
# :: build
task nixos:build HOST=nix-ops
# :: switch
task nixos:switch HOST=nix-ops

# : nixos, remote
# set DNS record then test ssh connections
# copy machineconfig to "hosts/{HOST}/hardware-configuration.nix"
# :: build
task nixos:build BUILDER=nix-dev HOST=nix-ops
# :: switch
task nixos:switch BUILDER=nix-dev HOST=nix-ops
```
