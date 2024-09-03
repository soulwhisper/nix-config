# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

origin repo = [bjw-s/nix-config](https://github.com/bjw-s/nix-config)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

```
# init
age-keygen --output $HOME/.config/age/keys.txt
find . -type f -name '*.sops.yaml' ! -name ".sops.yaml"
sops --encrypt --in-place xx.sops.yaml

# next
export SOPS_AGE_KEY_FILE=$HOME/.config/age/keys.txt

# push with gpg signed
export GPG_TTY=$(tty)
gpg --import 
git config --global user.signingkey <gpg-id>
git config --global commit.gpgsign true
```
## Notes
- networking.cloudflare.auth => CF-API:ZONE:DNS:EDIT
- change term font to "firacode-nerd-font" afterwards

## Usage

```shell
# install req. incl. cachix & nvd
curl -L https://nixos.org/nix/install | sh
nix-env -iA cachix -f https://cachix.org/api/v1/install
nix-env -iA nixpkgs.nvd

# import age keys
## darwin-before: /Users/<username>/Library/Application\ Support/sops/age/keys.txt
## darwin-after: /Users/<username>/.config/age/keys.txt

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
- remove 'unstable' brews, i.e. krr
