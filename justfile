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

[doc('Bootstrap dev environment: mise up, rtk init')]
[script]
bootstrap:
  #!/usr/bin/env bash
  set -euo pipefail

  # ---- 1. verify mise is available ----
  if ! command -v mise >/dev/null 2>&1; then
    echo "error: 'mise' not in PATH" >&2
    exit 1
  fi
  echo "mise $(mise --version 2>/dev/null || echo 'unknown')"
  echo ""

  # ---- 2. install/update mise tools ----
  echo ":: mise up"
  mise up
  echo ""

  # ---- 3. init rtk ----
  echo ":: rtk init"
  mise x -- rtk init -g --agent pi
  echo ""

  # ---- 4. verify omp is available ----
  if ! mise x -- omp --version >/dev/null 2>&1; then
    echo "error: 'omp' not available via mise" >&2
    exit 1
  fi
  echo "omp $(mise x -- omp --version 2>/dev/null || echo 'unknown')"
  echo ""

  echo "Done. Provider config is managed via Nix."
