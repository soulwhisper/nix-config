# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

This repository holds my NixOS configuration. It is fully reproducible and flakes based. Inspired by [bjw-s/nix-config](https://github.com/bjw-s/nix-config).

- soulwhisper-mba, my macbook configs.
- nix-dev, devops vm for corp-env.
- nix-nas, nas vm for corp-env. Homelab ver. using TrueNAS Scale 24.10+. Inspired by [Ramblurr/nixcfg#mali](https://github.com/Ramblurr/nixcfg/tree/main/hosts/mali).
- renovate configs and ci, managed by [soulwhisper/renovate-config](https://github.com/soulwhisper/renovate-config).

## Usage

```shell
# darwin
## opt. run set-proxy script first
sudo python3 scripts/darwin_set_proxy.py
## build & diff
task nix:darwin-build host=soulwhisper-mba
## deploy
task nix:darwin-deploy host=soulwhisper-mba
## opt. set default proxy after configs imported
cp scripts/set_proxy.fish ~/.config/fish/conf.d/

# nixos, e.g. nix-nas
## set DNS record then test ssh connections
## cp machineconfig
cp /etc/nixos/hardware-configuration.nix hosts/nix-nas/hardware-configuration.nix
## build & diff
task nix:nixos-build host=nix-nas
## deploy
task nix:nixos-deploy host=nix-nas
```
