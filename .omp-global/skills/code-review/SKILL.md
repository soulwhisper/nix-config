---
name: code-review
description: Use whenever committing, reviewing a diff/PR/staged changes, or working with pre-commit/prek/lint hooks — local lint verification before commits, plus the review checklist (secrets, destructive surface, Nix, shell, k8s/infra YAML) with severity floors.
---

# Code review & commit quality

Two halves of one pipeline: **verify locally before committing** (prek),
and **review against the checklist** (diffs, PRs, staged changes).

## Before every commit

`prek` is a drop-in Rust reimplementation of `pre-commit` — same
`.pre-commit-config.yaml`, faster, statically-linked.

- If the repo's git pre-commit hook is installed (`prek install`, one-time
  per clone), every `git commit` runs the hooks automatically — the shell
  enforces it, no agent action needed.
- Otherwise run `prek run` on staged changes before committing. Never
  commit over a failing hook with `--no-verify` unless the hook itself is
  broken (verify by running it manually first).
- `SKIP=<id> git commit …` is a permitted escape hatch only for broken
  hooks or fixtures that must live as-is — never for "just a lint nit".

### Discover the repo's hooks — don't assume

Hook sets differ per repo; the config file is the truth, not memory:

```bash
cat .pre-commit-config.yaml      # hook ids, args, file scoping, pinned revs
ls .gitleaks.toml .yamllint.yaml .markdownlint* 2>/dev/null   # tuning files
```

### Daily commands

```bash
prek run               # hooks on staged changes
prek run --all-files   # whole repo
prek run <hook-id>     # single hook
prek autoupdate        # bump hook revs
```

### Diagnosing failures

```bash
prek run --verbose <hook-id>            # what the hook is actually doing
prek run <hook-id> --files <one-file>   # narrow to one file
```

1. The error's file:line:col is almost always precise — read it first.
2. Secret scanners (gitleaks, detect-private-key): false positives are
   usually example values that look real. Replace with `REDACTED`/`xxx`,
   or allowlist with a targeted path scope — never a blanket rule.
3. Autofix linters (statix, ruff, shfmt): the suggested fix is usually
   correct; apply it.

### Adding a hook

Pin a release tag, scope with `files:`, then `prek autoupdate` +
`prek run --all-files <hook-id>`. Commit as `chore(pre-commit): add <hook>`.
Check CI workflows first so the hook doesn't duplicate or contradict CI.

## Reviewing a diff or PR

Procedure (from the retired `/review` command):

1. `git diff` / `git diff --cached` to see the changed range — know exactly
   what you're approving.
2. Read each touched file in full; the bug is often outside the hunk.
3. Run the repo's check entrypoint if one exists (`just --list` → lint /
   check recipe, or `prek run --all-files`).
4. Walk the checklist below, section by section.
5. Report findings Critical / High / Medium / Low with file:line and a
   suggested fix.

Hard floor: never approve a diff that adds a credential, loosens sops/age
protection, or weakens destructive-command gating.

## Review checklist

Ordered by severity ceiling — earlier violations are usually higher
severity. Items the harness or default review already guarantees are
deliberately omitted; this is the project-specific residue.

### 1. Secrets and credentials (Critical floor)

- [ ] No hardcoded token, key, password, or private key in the diff.
- [ ] New secret files follow the repo's encryption convention — discover
      it (`ls **/*.sops.*`, repo docs) rather than assuming a layout.
- [ ] No `--no-verify` past pre-commit. If a scanner triggered,
      investigate, don't bypass.

### 2. Destructive surface

- [ ] Migrations and CRD changes have a documented rollback path.
- [ ] Anything running at activation/apply time is idempotent on re-run.

### 3. Nix-specific

- [ ] Module additions use `mkIf cfg.enable`; no top-level pollution when
      disabled.
- [ ] No IFD (`builtins.readFile` of a build output, `fetchGit` of a
      private repo) inside `config = …`.
- [ ] No `home.file` for files the consuming CLI writes at runtime (EROFS
      trap) — use `home.activation` with seed-on-absent or merge.

### 4. Shell-specific

- [ ] `set -euo pipefail` at the top of new scripts.
- [ ] Expansions quoted unless intentional; `shellcheck` clean or
      disabled with a one-line reason.
- [ ] Re-running produces the same end state (idempotent).

### 5. Kubernetes / infra YAML

- [ ] No bare `latest` tag on images going into anything stateful.
- [ ] Resource requests/limits set, or explicitly documented as omitted.
- [ ] No `privileged: true` / `hostNetwork: true` / `hostPID: true`
      without justification.
- [ ] Secrets referenced via `secretKeyRef`, never inline.

### Severity defaults

- §1, §2 → Critical/High; do not approve.
- §3, §4, §5 → High to Medium depending on impact.
- Missing regression test for a real bug → High; otherwise tests → Medium.
- Style/hygiene → Low, Medium when it confuses future readers.
