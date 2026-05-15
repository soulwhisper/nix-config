---
name: shell-scripting
description: Use whenever writing or modifying shell scripts — `.sh` files, justfile recipes, hooks, sops templates, or any bash/sh fragment embedded in Nix. Trigger especially for bootstrap scripts, CI snippets, and anything intended to be re-runnable. Idempotency is the goal, not just exit-code zero.
---

# Shell scripting

This config leans on shell for the "glue" between Nix declarations and CLI
tools that don't have a declarative interface (claude plugin install,
kubectl bootstrap, sops rotate). Keep that glue boring and idempotent.

## Top of every script

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- `set -e`     — exit on first error.
- `set -u`     — unset variables are errors (catches typos).
- `set -o pipefail` — failure in any pipe stage fails the whole pipeline.
- Restricted `IFS` — defends against word-splitting bugs in `for x in …`.

For justfile recipes you can rely on `set -euo pipefail` at the top of each
`[script]` recipe explicitly, since `just` doesn't insert it.

## Idempotency patterns

**Check before act.** Don't rely on the tool to be idempotent — query
state, then act conditionally. Example from `just claude-bootstrap`:

```bash
installed=$(claude plugin list 2>/dev/null || echo "")
for plugin in "${PLUGINS[@]}"; do
  if grep -qF -- "${plugin}" <<< "$installed"; then
    claude plugin update "${plugin}" || echo "  warn: update non-zero" >&2
  else
    claude plugin install "${plugin}"
  fi
done
```

- `grep -qF` — `-q` quiet, `-F` literal (no regex), `--` end-of-options.
  Use `-w` when matching a friendly name to avoid prefix collisions
  (`anthropics` vs `anthropics-foo`).
- The `|| echo` softens a non-zero exit code when "already latest" is the
  cause; the warning surfaces real failures.

**Data-driven, not hand-written.** Lists at the top, loop at the bottom.
Adding an item later only touches the list.

```bash
declare -A MARKETS=(
  [claude-code-plugins]="anthropics/claude-code"
)
PLUGINS=(
  "commit-commands@claude-code-plugins"
  "code-review@claude-code-plugins"
)
```

## Quoting

- Quote every variable expansion unless you have a specific reason not to.
  `"$var"`, `"${arr[@]}"`. Use `"${arr[@]:-}"` to handle empty arrays
  under `set -u`.
- Use `$()`, never backticks.
- For literal `$` in a Nix multi-line string that wraps bash, escape with
  `''$` (two single-quotes then `$`).

## Failure mode patterns

```bash
# A. Pre-flight: bail with a clear message if a dep is missing.
command -v claude >/dev/null 2>&1 || {
  echo "error: 'claude' not in PATH — run 'just darwin switch' first" >&2
  exit 1
}

# B. Cleanup on exit (and only on exit).
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# C. Bail-with-context. Don't swallow the original error.
some_command "$arg" || {
  rc=$?
  echo "some_command failed (exit $rc) on '$arg'" >&2
  exit $rc
}
```

## Linting

Pre-commit runs `shellcheck` and `shfmt`. Don't disable a lint without a
`# shellcheck disable=SC2086` comment and a one-line reason next to it.

The most common real findings:

- SC2086 — unquoted expansion. Almost always a bug; quote it.
- SC2155 — `local x=$(cmd)` masks the exit code of `cmd`. Split into a
  `local x` declaration and a separate assignment.
- SC2207 — read into array via `mapfile` or `IFS=$'\n' read -d ''`, not
  via `arr=($(cmd))`.

## When shell is the wrong tool

If your script:

- Parses more than trivial JSON → use `jq`. If it parses JSON and *also*
  has loops with conditionals → consider Python.
- Calls Kubernetes APIs imperatively → use kustomize/helm/manifest.
- Bootstraps things on every machine forever → consider a Nix module
  instead.

Bootstrap scripts that have to be imperative (CLI plugin install, sops key
import) stay in the justfile because they're one-shot and operator-driven.
Recurring "convergence" logic does not belong in shell.
