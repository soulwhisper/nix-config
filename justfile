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

[doc('Bootstrap or update Claude Code marketplaces and plugins (idempotent)')]
[script]
claude-bootstrap:
  if ! command -v claude >/dev/null 2>&1; then
    echo "error: 'claude' not in PATH — run 'just {darwin,nixos} switch' first" >&2
    exit 1
  fi
  if [ -L "$HOME/.claude/settings.json" ]; then
    echo "error: ~/.claude/settings.json is still a symlink to /nix/store" >&2
    echo "       run 'just darwin/nixos switch' to materialize it" >&2
    exit 1
  fi
  # ---- declarative plugin set ----
  # marketplace friendly-name -> github source (owner/repo, URL, or local path)
  declare -A MARKETS=(
    [claude-code-plugins]="anthropics/claude-code"
    [thedotmack]="thedotmack/claude-mem"
  )
  # plugins: "name@marketplace-friendly-name"
  PLUGINS=(
    "commit-commands@claude-code-plugins"
    "code-review@claude-code-plugins"
    "security-guidance@claude-code-plugins"
    "claude-mem@thedotmack"
  )
  # ---- 1. marketplaces ----
  echo ":: marketplaces"
  current_markets=$(claude plugin marketplace list 2>/dev/null || echo "")
  for name in "${!MARKETS[@]}"; do
    if grep -qw -- "${name}" <<< "$current_markets"; then
      echo "  ✓ ${name}"
    else
      echo "  + ${name} <- ${MARKETS[$name]}"
      claude plugin marketplace add "${MARKETS[$name]}"
    fi
  done
  # ---- 2. refresh catalogs (always; cheap git fetch) ----
  echo ":: refreshing catalogs"
  claude plugin marketplace update
  # ---- 3. plugins ----
  echo ":: plugins"
  installed=$(claude plugin list 2>/dev/null || echo "")
  for plugin in "${PLUGINS[@]}"; do
    if grep -qF -- "${plugin}" <<< "$installed"; then
      echo "  ↻ ${plugin}"
      if ! claude plugin update "${plugin}"; then
        echo "    warn: update returned non-zero (likely already latest or transient)" >&2
      fi
    else
      echo "  + ${plugin}"
      claude plugin install "${plugin}"
    fi
  done
  echo "Done. If a Claude session is open elsewhere, run /reload-plugins to pick up changes."
