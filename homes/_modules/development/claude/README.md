# Claude Code

```
claude-code/
├── default.nix      # home-manager module (wrapper, activation merge, asset symlinks)
├── settings.nix     # Nix-managed settings.json fragment (env, permissions, hooks, statusLine)
├── CLAUDE.md        # global memory (cross-repo, always loaded)
├── agents/          # sub-agents (planner, reviewer, infra-operator)
├── commands/        # slash commands (/plan, /review, /ship, /dryrun)
├── skills/          # trigger-based skills (six)
└── README.md        # this file
```

## How it works

- `agents/`, `commands/`, `skills/`, and `CLAUDE.md` are symlinked into `~/.claude/`
  via `home.file`.
- `settings.json` is built by an activation script that merges the Nix-managed fragment
  (`settings.nix`) with the existing file, using `jq` to preserve fields written by the
  CLI (e.g., `enabledPlugins`, `extraKnownMarketplaces`, `installedPlugins`). The
  result is a **writable** file, never a read-only store symlink.
- Plugins are explicitly excluded from Nix management – see contract with
  `just claude-bootstrap` below.

## Design rationale

### Agents – 3 sub-agents

| Agent              | Purpose                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| **planner**        | Discuss approach before writing code.                                                                                         |
| **reviewer**       | Pre-commit review covering both code quality and security in one pass.                                                        |
| **infra-operator** | Safe execution of infrastructure changes (K8s, Talos, NixOS). Enforces “read first, diff, confirm, apply, verify” discipline. |

These three agents map to the core loop of this repository: plan changes, review them thoroughly, and roll them out to infrastructure with explicit safety rails.

### Commands – 4 slash commands

| Command   | Action                                                     |
| --------- | ---------------------------------------------------------- |
| `/plan`   | Invoke the planner agent for design discussions.           |
| `/review` | Invoke the reviewer agent before committing.               |
| `/dryrun` | Show diffs (Nix, kubectl, helm, Talos) without executing.  |
| `/ship`   | Invoke infra-operator to apply changes after confirmation. |

Together they form a complete workflow: plan → review → dry-run → ship.

### Skills – 6 folder-based skills

Each skill lives in `skills/<name>/SKILL.md` and is triggered by its description.

| Skill                     | Purpose                                                                                            |
| ------------------------- | -------------------------------------------------------------------------------------------------- |
| **nix-flake**             | Flake workflows, `nix flake check`, error patterns for `nixos-rebuild`.                            |
| **k8s-talos-ops**         | Safe kubectl/talosctl/helm operations; always `get` → `diff` → `apply` → verify.                   |
| **secrets-sops**          | sops-nix invariants; forms a double guard with `permissions.deny` paths.                           |
| **shell-scripting**       | Shell script style guide, covers `just claude-bootstrap` and similar scripts.                      |
| **code-review-checklist** | Checklist the reviewer agent reads on every invocation.                                            |
| **prek-hooks**            | Index of pre-commit hooks (gitleaks, statix, deadnix, shellcheck, shfmt, ruff, markdownlint-cli2). |

These skills are explicitly tailored to the Nix + Kubernetes + Talos stack, the
secrets management pipeline, and the pre-commit quality gates used in this repo.

### `CLAUDE.md` – global memory

All persistent rules and conventions that apply to every session live in a single
`CLAUDE.md` file. This reduces context-fetching overhead compared to spreading
them across multiple files, while ensuring the model always has the right
constraints from the first message.

### Hooks – minimal formatting

Only two `PostToolUse` hooks are configured:

- `.nix` files → `nixfmt`
- `.sh` files → `shfmt -w`

Everything else is handled by the built-in permission system (`permissions.deny`
and `permissions.ask` for dangerous commands) and Claude’s own memory system
(for session persistence). No additional hooks are needed.

### Plugins – kept out of Nix management

The fields `enabledPlugins`, `extraKnownMarketplaces`, and `installedPlugins`
are explicitly **removed** from the Nix-managed fragment in the activation
script. This allows the CLI to write to these fields freely during normal
operation (e.g., `plugin install`) without fear of being overwritten by the next
`home-manager switch`.

## Contract with `just claude-bootstrap`

The Nix module provides:

- A **writable** `~/.claude/settings.json`
- A merge strategy that protects CLI-owned fields

`just claude-bootstrap` is responsible for:

- `marketplace add` / `update`
- `plugin install` / `update` (idempotent)

The only shared interface is `~/.claude/settings.json`; neither side modifies
the other’s managed state.
