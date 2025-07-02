# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

- soulwhisper-mba, my macbook configs.
- nix-infra, production vm, for homelab infrastructure.
- nix-ops, staging vm, for tests and various operations.
- nix-dev, laptop llm workstation, with Nvidia GPU. ZFS-Impermanence.
- renovate configs and ci, managed by [soulwhisper/renovate-config](https://github.com/soulwhisper/renovate-config).

## Usage

```shell
# if bootstrap, check 'bootstrap/README.md'
git clone https://github.com/soulwhisper/nix-config

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

# : build and try pkgs
nix build nix-config/.#zotregistry --print-out-paths
```

## Inspiration

I got help from some cool configs like:

- [bjw-s/nix-config](https://github.com/bjw-s/nix-config)
- [Ramblurr/nixcfg](https://github.com/Ramblurr/nixcfg)
- [ckiee/nixfiles](https://github.com/ckiee/nixfiles)
- [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)
