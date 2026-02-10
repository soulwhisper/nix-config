set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

ROOT_DIR := invocation_directory()

[private]
default:
  @just --list

[doc('Build nixos configuration, HOST required')]
build HOST:
  nix-shell -p nixos-rebuild --run "nixos-rebuild build --flake {{ROOT_DIR}}/.#{{HOST}}"

[doc('Switch nixos configuration, HOST required')]
switch HOST:
  nix-shell -p nixos-rebuild --run "sudo nixos-rebuild switch --flake {{ROOT_DIR}}/.#{{HOST}}"
