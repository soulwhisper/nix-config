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

[doc('Bootstrap omp: verify, seed local assets to ~/.omp/agent, fetch remote skills')]
[script]
omp-bootstrap:
  #!/usr/bin/env bash
  set -euo pipefail

  # ---- 1. verify omp is available ----
  if ! command -v omp >/dev/null 2>&1; then
    echo "error: 'omp' not in PATH — run 'just {darwin,nixos} switch' first" >&2
    exit 1
  fi
  echo "omp $(omp --version 2>/dev/null || echo 'unknown')"
  echo ""

  # ---- 2. seed local .omp/ -> ~/.omp/agent/ (idempotent) ----
  AGENT="$HOME/.omp/agent"
  REPO="{{invocation_directory()}}"

  _seed_dir() {
    local src="$1" dst="$2" label="$3"
    [ -d "$src" ] || return
    mkdir -p "$dst"
    local added=0 skipped=0
    while IFS= read -r -d "" file; do
      rel="${file#$src/}"
      if [ ! -e "$dst/$rel" ]; then
        install -D -m 0644 "$file" "$dst/$rel"
        ((added++))
      else
        ((skipped++))
      fi
    done < <(find "$src" -type f -print0)
    echo "  ${label}: +${added} new, ${skipped} existing"
  }

  echo ":: local assets (.omp/ -> ~/.omp/agent/)"
  _seed_dir "$REPO/.omp/skills"   "$AGENT/skills"   "skills"
  _seed_dir "$REPO/.omp/commands" "$AGENT/commands" "commands"
  _seed_dir "$REPO/.omp/agents"   "$AGENT/agents"   "agents"
  echo ""

  # ---- 3. fetch/update remote skills ----
  fetch_github_skill() {
    local spec="$1" name="$2"
    local owner repo ref subdir
    owner="${spec%%/*}"; spec="${spec#*/}"
    repo="${spec%%/*}";  spec="${spec#*/}"
    subdir="${spec%%@*}"; ref="${spec##*@}"

    local cache="$HOME/.cache/omp-skills/${owner}_${repo}_${ref//\//_}"
    if [ -d "$cache" ]; then
      echo "  ↻ ${name}: pulling ${ref}..."
      git -C "$cache" fetch --depth 1 origin "$ref" 2>/dev/null || true
      git -C "$cache" checkout -q FETCH_HEAD 2>/dev/null || true
    else
      echo "  ↓ ${name}: cloning ${owner}/${repo}@${ref}..."
      git clone --depth 1 --branch "$ref" \
        "https://github.com/${owner}/${repo}.git" "$cache" >/dev/null 2>&1
    fi

    local src="$cache/${subdir:-.}"
    local dst="$AGENT/skills/$name"
    if [ -d "$src/SKILL.md" ]; then src="$src/SKILL.md"; fi
    if [ ! -e "$dst" ]; then
      install -D -m 0644 "$src" "$dst" 2>/dev/null || cp -r "$src" "$dst"
      echo "    + installed"
    else
      echo "    ✓ up to date"
    fi
  }

  echo ":: remote skills"
  # Add remote skill specs below.
  # Format: fetch_github_skill "owner/repo/subdir@ref" "skill-name"
  # Example:
  # fetch_github_skill "anthropics/skills/skills/pdf@b0cbd3df" "pdf"

  echo "  (no remote skills configured)"
  echo ""
  echo "Done. Provider config is managed via Nix."
