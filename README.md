# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

- soulwhisper-mba, my macbook configs.
- nix-infra, production infra vm, for talos. Without ZFS.
- nix-nas, staging nas vm. With ZFS. Was TrueNAS Scale 24.10+.
- nix-dev, llm dev workstation. Must have Nvidia GPU.
- renovate configs and ci, managed by [soulwhisper/renovate-config](https://github.com/soulwhisper/renovate-config).

## Usage

```shell
# darwin
## opt. run set-proxy script
sudo python3 scripts/darwin_set_proxy.py
## build & diff
task nix:darwin-build HOST=soulwhisper-mba
## deploy
task nix:darwin-deploy HOST=soulwhisper-mba

# nixos, remote
## set DNS record then test ssh connections
## cp machineconfig
cp /etc/nixos/hardware-configuration.nix hosts/nix-nas/hardware-configuration.nix
## build & diff
task nix:nixos-build HOST=nix-nas
## deploy
task nix:nixos-deploy HOST=nix-nas

# nixos, local
git clone https://github.com/soulwhisper/nix-config
nixos-rebuild build --flake nix-config/.#nix-nas --show-trace --print-build-logs
nixos-rebuild switch --flake nix-config/.#nix-nas

# darwin, local
git clone https://github.com/soulwhisper/nix-config
sudo python3 nix-config/scripts/darwin_set_proxy.py
sudo darwin-build build --flake nix-config/.#soulwhisper-mba --show-trace
sudo nvd diff /run/current-system result
sudo darwin-rebuild switch --flake nix-config/.#soulwhisper-mba
```

## Inspiration

I got help from some cool configs like:

- [bjw-s/nix-config](https://github.com/bjw-s/nix-config)
- [Ramblurr/nixcfg](https://github.com/Ramblurr/nixcfg)
- [ckiee/nixfiles](https://github.com/ckiee/nixfiles)
- [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)
