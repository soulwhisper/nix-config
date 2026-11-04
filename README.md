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
git clone https://github.com/soulwhisper/nix-config
cd nix-config

# : darwin
brew install just
# :: build & diff
just darwin build soulwhisper-mba
# :: switch
just darwin switch soulwhisper-mba

# : nixos
nix-shell -p just
# :: build the clean pinned revision on the controller
REVISION=$(git rev-parse HEAD)
SYSTEM=$(just nixos build nix-ops "$REVISION")
# :: plan and inspect before explicitly approving remote activation
PLAN="$HOME/nix-ops-deploy.json"
just nixos plan nix-ops "$SSH_TARGET" "$REVISION" "$SYSTEM" "$PLAN"
just nixos diff "$PLAN"
just nixos deploy "$PLAN" "$REVIEWED_DEPLOY_APPROVAL"

# : build and try pkgs
nix build .#deployment-tools --print-out-paths
```

NixOS deployment requires a verified SSH target and a reviewed approval printed
by `plan`; plan files stay outside the clean checkout. Darwin controllers need an
explicit Linux builder or a CI-built closure. See
[corporate services](docs/corporate-services.md) before enabling `nix-dev`'s
PKI/Forgejo deployment: production issuer material must be filled in SOPS first.

## Inspiration

I got help from some cool configs like:

- [bjw-s/nix-config](https://github.com/bjw-s/nix-config)
- [Ramblurr/nixcfg](https://github.com/Ramblurr/nixcfg)
- [ckiee/nixfiles](https://github.com/ckiee/nixfiles)
- [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)
