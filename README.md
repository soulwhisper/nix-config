# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

origin repo = [bjw-s/nix-config](https://github.com/bjw-s/nix-config)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

## Usage

```shell
# run set-proxy script if necessary
sudo python3 scripts/darwin_set_proxy.py

# darwin
## opt. build / test
task nix:darwin-build host=soulwhisper-mba
## deploy
task nix:darwin-deploy host=soulwhisper-mba

# nixos
task nix:nixos-deploy host=nix-vm

# install 'unstable' brews
brew install robusta-dev/homebrew-krr/krr
```

## Changelog
- modify hostname and username from origin
- add a nix-daemon set-proxy script
