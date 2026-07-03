set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

mod darwin ".justfiles/darwin.just"
mod nixos ".justfiles/nixos.just"

[private]
default:
  @just --list

[doc('Lint all files')]
[script]
lint:
  prek run --all-files

[doc('Cleanup generations and unused nixpkgs')]
[script]
cleanup:
  echo "Cleanup generations..."
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d
  nix profile wipe-history --profile /home/soulwhisper/.local/state/nix/profiles/home-manager --older-than 7d
  echo "Cleanup unused nixpkgs..."
  sudo nix-collect-garbage --delete-older-than 7d
  nix-collect-garbage --delete-older-than 7d
