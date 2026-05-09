set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

ROOT_DIR := invocation_directory()
default_host := 'soulwhisper-mba'

[private]
default:
  @just --list

[doc('Initialize nix-darwin configuration')]
[script]
init HOST=default_host:
  sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake "{{ROOT_DIR}}/#{{HOST}}"

[doc('Build nix-darwin configuration')]
[script]
build HOST=default_host:
  sudo darwin-rebuild build --flake "{{ROOT_DIR}}/#{{HOST}}"
  sudo nvd diff /run/current-system result

[doc('Switch nix-darwin configuration')]
[script]
switch HOST=default_host:
  sudo darwin-rebuild switch --flake "{{ROOT_DIR}}/#{{HOST}}"
