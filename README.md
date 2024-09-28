# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

- repo structure and macbook configs, inspired by [bjw-s/nix-config](https://github.com/bjw-s/nix-config).
- workstaion configs, inspired by [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config).
- nas configs, inspired by [Ramblurr/nixcfg#mali](https://github.com/Ramblurr/nixcfg/tree/main/hosts/mali).

## Usage

```shell
# darwin
## opt. run set-proxy script first
sudo python3 scripts/darwin_set_proxy.py
## build & diff
task nix:darwin-build host=soulwhisper-mba
## deploy
task nix:darwin-deploy host=soulwhisper-mba

# nixos, e.g. nix-nas
## set DNS record then test ssh connections
## cp machineconfig
cp /etc/nixos/hardware-configuration.nix hosts/nix-nas/hardware-configuration.nix
## build & diff
task nix:darwin-build host=nix-nas
## deploy
task nix:darwin-deploy host=nix-nas

# install 'unstable' brews
brew install robusta-dev/homebrew-krr/krr
```
