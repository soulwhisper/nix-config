# Operating Principles for This Workstation

This file is global memory for Claude Code, shipped via home-manager. It applies
across every repo opened on this user's machines. Per-repo `CLAUDE.md` files override what's here.

## 1. Always-on rules

- **Context first.** Before editing or proposing changes, read the files you're
  about to touch. Do not pattern-match from memory.
- **Edit, don't rewrite.** Prefer targeted patches. Wholesale rewrites destroy
  blame history and review-ability.
- **Plan before destructive work.** Anything that mutates infra, deletes data,
  upgrades a node, or runs `*-rebuild`/`apply`/`switch` must produce a plan
  (diff, dry-run, or written summary) before execution.
- **One feature, one branch, atomic commit.** Conventional commits
  (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `ci:`, `perf:`).
- **Secrets are radioactive.** Never echo, log, or paste a token or key.
  Sops-encrypted files (`*.sops.*`, `*.age`, `~/.config/{age,sops}/`) are
  permission-denied in `settings.json`; do not work around the deny list.
- **Reversibility.** Prefer changes you can roll back with one command:
  `home-manager generations`, `nixos-rebuild --rollback`, `talosctl rollback`,
  `helm rollback`. If a change is one-way, say so before doing it.

## 2. Environment

- OS: NixOS (`nix-infra`, `nix-ops`) and macOS (`soulwhisper-mba`).
- Shell: `fish`. Task runner: `just`. Pre-commit: `prek` (Rust port).
- Secrets: `sops-nix` with bare-token files at `/run/user/*/secrets/`.
- Infra: a Talos-based Kubernetes homelab.
- The Claude Code package is a wrapped derivation that injects auth from a
  bare-token file and routes to DeepSeek's Anthropic-compatible endpoint by
  default. To force the real Anthropic API for one invocation:
  `CLAUDE_USE_ANTHROPIC=1 claude`.

## 3. Tool routing

Reach for tools in this order:

1. Read-only inspection (`git diff`, `nix flake show`, `kubectl get`,
   `talosctl get`, `helm diff`). These are pre-approved in `permissions.allow`.
2. Build / check (`nix build`, `nix flake check`, `just check`).
3. Apply / mutate. These require explicit user confirmation; they're in
   `permissions.ask` for a reason — surface the diff, get a yes.

## 4. Output style

- Reasoning thorough, prose terse.
- No sycophantic openers (`Great question!`) or closing fluff
  (`Hope this helps!`).
- When unsure, say so. Don't fabricate file paths, command flags, or option
  names — search the repo or man-page first.
- Source-of-truth wins over assumptions: when nix-config says one thing and
  the running system says another, both facts go in the report.

## 5. When to delegate

These agents are available in `.claude/agents/`:

- `planner` — break complex changes into reviewable steps before any edit.
- `reviewer` — code/config review against the checklist skill.
- `infra-operator` — Kubernetes / Talos / Nix host operations with the
  read-only-first, dry-run, confirm-before-mutate discipline.

Skills in `.claude/skills/` activate on topic; trust their gating.

## 6. Plugin baseline

The Anthropic-blessed plugins are bootstrapped imperatively via
`just claude-bootstrap`:

- `commit-commands@claude-code-plugins`
- `code-review@claude-code-plugins`
- `security-guidance@claude-code-plugins`

These are CLI-installed state and live outside the home-manager generation
on purpose; if the list above changes, edit the justfile, not `settings.nix`.
