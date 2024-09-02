# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

* [X] correct hosts, remove not matched
* [X] rename hostname
* [X] remove deploy-rs
* [X] add git.signingKey at "/homes/soulwhisper/default.nix"
* [X] change atuin configs at "/homes/soulwhisper/default.nix"
* [X] gen new ssh-ed25519 key at "/homes/soulwhisper/config/ssh/ssh.pub"
* [X] update "*.sops.yaml"

* homes.bjw-s -> homes.soulwhisper
* bjw-s.internal -> homelab.internal
* mv "hosts/_modules/darwin/os-defaults.nix" -> "archived"

```shell
# push with gpg signed
export GPG_TTY=$(tty)
gpg --import 
git config --global user.signingkey <gpg-id>
git config --global commit.gpgsign true

```

# Readme

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

Deployment is done using [deploy-rs][deploy-rs] and [nix-darwin][nix-darwin], see [usage](#usage).

Notes: networking.cloudflare.auth => CF-API:ZONE:DNS:EDIT

```
# init
age-keygen --output $HOME/.config/age/keys.txt
find . -type f -name '*.sops.yaml' ! -name ".sops.yaml"
sops --encrypt --in-place xx.sops.yaml

# next
export SOPS_AGE_KEY_FILE=$HOME/.config/age/keys.txt
```

## Hosts

- Nix-VM,
- Nix-NAS, need correction for zfs / minio / nginx / chrony, not public

## Usage

```shell
# darwin
## opt. build / test
task nix:darwin-build host=soulwhisper-mba
## deploy
task nix:darwin-deploy host=soulwhisper-mba

# nixos
task nix:nixos-deploy host=nix-vm
```

#### Darwin

Apply a Darwin configuration to the local machine:

```console
$ task nix:apply-darwin host=soulwhisper-mba
```
