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

[doc('Verify omp is available (installed declaratively via mise)')]
[script]
omp-bootstrap:
  if ! command -v omp >/dev/null 2>&1; then
    echo "error: 'omp' not in PATH — run 'just {darwin,nixos} switch' first" >&2
    exit 1
  fi
  omp_ver=$(omp --version 2>/dev/null || echo "unknown")
  echo "omp ${omp_ver} ready."
  echo "Provider config is managed via Nix (DEEPSEEK_API_KEY from sops, DEEPSEEK_BASE_URL set)."
  echo "Skills, commands, and extensions are self-managed by omp under ~/.omp/."
