---
name: prek-hooks
description: Use whenever pre-commit, prek, lint config, or any of the hooks (gitleaks, statix, deadnix, shellcheck, shfmt, ruff, markdownlint, nixfmt) come up — installing, debugging a hook failure, adding a new hook, or skipping one safely. `prek` is the Rust-based pre-commit runner used in this repo.
---

# Pre-commit via `prek`

`prek` is a drop-in Rust reimplementation of `pre-commit` — same
`.pre-commit-config.yaml`, faster and statically-linked, no Python.

## Daily commands

```bash
prek run               # run hooks on staged changes (default at commit time)
prek run --all-files   # run hooks across the whole repo
prek run <hook-id>     # run a single hook
prek install           # install the git hook (one-time per clone)
prek autoupdate        # bump hook versions in config
```

## Hook inventory in this repo

| ID                  | What it does                                           | When it fires |
|---------------------|--------------------------------------------------------|---------------|
| `gitleaks`          | Scans staged content for secret-shaped strings         | commit-msg / pre-commit |
| `statix-check`      | Nix anti-pattern lint                                  | `*.nix` |
| `deadnix`           | Unused bindings / imports in Nix                       | `*.nix` |
| `nixfmt-tree`       | Format Nix in directory-tree mode                      | `*.nix` |
| `shellcheck`        | Bash lint                                              | `*.sh`, executable shebangs |
| `shfmt`             | Bash formatter                                         | `*.sh` |
| `ruff`              | Python lint + format                                   | `*.py` |
| `markdownlint-cli2` | Markdown lint                                          | `*.md` |

## Diagnosing failures

```bash
prek run --verbose <hook-id>   # see what the hook is actually doing
prek run <hook-id> --files <one-file>   # narrow to a single file
```

If the hook reports something you don't understand:

1. Read the error line carefully — the file:line:col is almost always
   precise.
2. For `gitleaks`, check the matched rule name and the literal that
   triggered it. False positives are usually example values that look
   real; either replace with `REDACTED`/`xxx` or extend
   `.gitleaks.toml` with a targeted allowlist (path scope, not blanket).
3. For `statix`/`deadnix`, the suggested fix is often correct. Apply with
   `statix fix <file>` or by hand.

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
prek autoupdate            # let prek normalize the rev format
prek run --all-files <hook-id>   # smoke-test
```

Commit with a `chore(pre-commit): add <hook>` message.

## When NOT to skip

Skipping a hook (`SKIP=<id> git commit …`) is a permitted escape hatch
when:

- The hook itself is broken (rare; verify by running it manually first).
- The file genuinely needs to live as it is (generated lockfile, vendored
  binary fixture).

Skipping is **not** appropriate for:

- "It's just a lint nit" — fix it.
- "It's a hardcoded test key" — replace with a fixture value that doesn't
  match the gitleaks rule, or allowlist with a path-scoped rule.
- "I'll fix it in a follow-up PR" — no, follow-up PRs never come.

## Nixfmt conflict

Both `nixfmt-tree` (a pre-commit hook) and the `PostToolUse` hook in
`settings.json` (per-file `nixfmt` after Claude edits) run `nixfmt`. They
should converge on the same output. If they don't, one of them is using a
different binary or version — check `which nixfmt` and the pinned hook
revision.
