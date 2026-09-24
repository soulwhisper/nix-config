---
name: prek-hooks
description: Use whenever pre-commit, prek, lint config, or a hook failure comes up — installing, debugging a hook failure, adding a new hook, or skipping one safely. `prek` is the Rust-based drop-in replacement for pre-commit.
---

# Pre-commit via `prek`

`prek` is a drop-in Rust reimplementation of `pre-commit` — same
`.pre-commit-config.yaml`, faster and statically-linked, no Python.

## Discover the repo's hooks — don't assume

Hook sets differ per repo. Before diagnosing or advising, read the actual
config:

```bash
# The inventory: hook ids, args, file scoping, and pinned revs
cat .pre-commit-config.yaml

# Repo-specific tuning (allowlists, excludes) often lives beside it
ls .gitleaks.toml .yamllint.yaml .markdownlint* 2>/dev/null
```

Never quote a hook inventory from memory — the config file is the truth.

## Daily commands

```bash
prek run               # run hooks on staged changes (default at commit time)
prek run --all-files   # run hooks across the whole repo
prek run <hook-id>     # run a single hook
prek install           # install the git hook (one-time per clone)
prek autoupdate        # bump hook versions in config
```

## Diagnosing failures

```bash
prek run --verbose <hook-id>        # see what the hook is actually doing
prek run <hook-id> --files <one-file>   # narrow to a single file
```

If the hook reports something you don't understand:

1. Read the error line carefully — the file:line:col is almost always
   precise.
2. Secret scanners (gitleaks, detect-private-key): check the matched rule
   and the literal that triggered it. False positives are usually example
   values that look real; either replace with `REDACTED`/`xxx` or extend
   the scanner's allowlist with a targeted path scope, not a blanket rule.
3. Linters with autofix (statix, ruff, shfmt): the suggested fix is often
   correct. Apply the tool's fix mode or fix by hand.

## Adding a new hook

Edit `.pre-commit-config.yaml`:

```yaml
- repo: https://github.com/<owner>/<repo>
  rev: <pinned-version>     # pin a release tag, not a branch
  hooks:
    - id: <hook-id>
      args: [--check]       # if applicable
      files: \.(yaml|yml)$  # narrow the scope
```

Then:

```bash
prek autoupdate                    # let prek normalize the rev format
prek run --all-files <hook-id>     # smoke-test
```

Commit with a `chore(pre-commit): add <hook>` message. If the repo has CI
lint workflows (check `.github/workflows/` / `.woodpecker/`), make sure the
new hook doesn't duplicate or contradict a CI check.

## When NOT to skip

Skipping a hook (`SKIP=<id> git commit …`) is a permitted escape hatch
when:

- The hook itself is broken (rare; verify by running it manually first).
- The file genuinely needs to live as it is (generated lockfile, vendored
  binary fixture).

Skipping is **not** appropriate for:

- "It's just a lint nit" — fix it.
- "It's a hardcoded test key" — replace with a fixture value that doesn't
  match the scanner rule, or allowlist with a path-scoped rule.
- "I'll fix it in a follow-up PR" — no, follow-up PRs never come.
