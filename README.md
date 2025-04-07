# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

- soulwhisper-mba, my macbook configs.
- nix-infra, production infra vm, for talos. ZFS-Impermanence.
- nix-nas, staging nas vm. ZFS-Impermanence. Was TrueNAS Scale 24.10+.
- nix-dev, llm dev workstation. Must have Nvidia GPU.
- renovate configs and ci, managed by [soulwhisper/renovate-config](https://github.com/soulwhisper/renovate-config).

## Usage

```shell
git clone https://github.com/soulwhisper/nix-config

# darwin
## opt. run set-proxy script
sudo python3 scripts/darwin_set_proxy.py
## build & diff
task nix:darwin-build HOST=soulwhisper-mba
## switch
task nix:darwin-switch HOST=soulwhisper-mba

# nixos, local
## build
task nix:nixos-build HOST=nix-nas
## switch
task nix:nixos-switch HOST=nix-nas

# nixos, remote
## set DNS record then test ssh connections
## copy machineconfig to "hosts/{HOST}/hardware-configuration.nix"
## build
task nix:nixos-build MODE=remote-to-remote SOURCE_HOST=nix-dev SOURCE_DOMAIN=homelab.internal TARGET_HOST=nix-nas TARGET_DOMAIN=homelab.internal
## switch
task nix:nixos-switch MODE=local-to-remote HOST=nix-nas DOMAIN=homelab.internal

# build and try pkgs
nix build nix-config/.#zotregistry --print-out-paths
```

## Inspiration

I got help from some cool configs like:

- [bjw-s/nix-config](https://github.com/bjw-s/nix-config)
- [Ramblurr/nixcfg](https://github.com/Ramblurr/nixcfg)
- [ckiee/nixfiles](https://github.com/ckiee/nixfiles)
- [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)
