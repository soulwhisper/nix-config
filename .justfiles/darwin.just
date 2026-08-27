set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

ROOT_DIR := invocation_directory()

[private]
default:
  @just --list

[doc('Initialize nix-darwin configuration, HOST required')]
[script]
init HOST:
  sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake "{{ROOT_DIR}}/#{{HOST}}"

[doc('Build nix-darwin configuration, HOST required')]
[script]
build HOST:
  sudo darwin-rebuild build --flake "{{ROOT_DIR}}/#{{HOST}}"
  sudo nvd diff /run/current-system result

[doc('Switch nix-darwin configuration, HOST required')]
[script]
switch HOST:
  sudo darwin-rebuild switch --flake "{{ROOT_DIR}}/#{{HOST}}"
