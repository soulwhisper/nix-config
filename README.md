# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

- soulwhisper-mba, my macbook configs.
- soulwhisper-studio, my macstudio configs.
- nix-dev, vm for production development.
- nix-ops, vm for homelab infrastructure.
- renovate configs and ci, managed by [soulwhisper/renovate-config](https://github.com/soulwhisper/renovate-config).

## Documentation

See [docs/README.md](docs/README.md) — secrets workflow, service notes, port registry, runbook, and decision log.

## Usage

```shell
# if bootstrap, check 'bootstrap/README.md'
git clone https://github.com/soulwhisper/nix-config

# deps: nix
curl -L https://nixos.org/nix/install | sh

# : darwin
brew install just
# :: opt. run set-proxy script
sudo python3 bootstrap/darwin_set_proxy.py
# :: init, if darwin-rebuild not exist
just darwin init soulwhisper-mba
# :: build & diff
just darwin build soulwhisper-mba
# :: switch
just darwin switch soulwhisper-mba

# : nixos
nix-shell -p just
# :: build
just nixos build nix-ops
# :: switch
just nixos switch nix-ops

# : build and try pkgs
nix build nix-config/.#zotregistry --print-out-paths
```

## Inspiration

I got help from some cool configs like:

- [bjw-s/nix-config](https://github.com/bjw-s/nix-config)
- [Ramblurr/nixcfg](https://github.com/Ramblurr/nixcfg)
- [ckiee/nixfiles](https://github.com/ckiee/nixfiles)
- [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)
