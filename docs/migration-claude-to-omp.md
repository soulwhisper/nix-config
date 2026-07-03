# Migration Plan: Claude Code → Oh My Pi

**Date**: 2026-07-03  
**Status**: Draft  
**Scope**: Deprecate `modules.development.claude` Nix module, migrate all config/assets to omp-native layout, remove `just claude-bootstrap`.

---

## 1. Current State Inventory

### 1.1 Nix Module (`homes/_modules/development/claude/`)

| File | Purpose |
|------|---------|
| `default.nix` | 198-line home-manager module: wrapper auth injection, settings merge activation, asset seeding |
| `settings.nix` | Managed `settings.json` fragment (env, permissions, hooks, statusLine) |
| `CLAUDE.md` | Global memory — cross-repo conventions, tool routing, agents/skills catalog |
| `README.md` | Module documentation |
| `agents/` | 3 sub-agents: `planner.md`, `reviewer.md`, `infra-operator.md` |
| `commands/` | 4 slash commands: `plan.md`, `review.md`, `ship.md`, `dryrun.md` |
| `skills/` | 8 skills: `code-review-checklist`, `context-budget`, `iterative-retrieval`, `k8s-talos-ops`, `prek-hooks`, `secrets-sops`, `shell-scripting`, `verification-loop` |

### 1.2 Consumer References

| File | Reference |
|------|-----------|
| `homes/soulwhisper/default.nix:16-17` | `development.claude.enable = true; development.claude.authFile = ...` |
| `homes/soulwhisper/secrets/default.nix:22-24` | `"dev/claude/auth"` sops secret |
| `homes/soulwhisper/secrets/secrets.sops.yaml:2-3` | Encrypted `dev.claude.auth` token |
| `homes/_modules/development/default.nix:8` | `imports = [ ./claude ]` |
| `justfile:30-81` | `claude-bootstrap` recipe |
| `docs/notes.md:77-78` | Bootstrap docs reference `just claude-bootstrap` |
| `homes/_modules/shell/utilities/default.nix:53` | mise plugin: `github:can1357/oh-my-pi` (already present) |

### 1.3 Runtime Dependencies

| Dependency | Used For |
|------------|----------|
| `pkgs.unstable.claude-code` | Upstream Claude Code package (wrapped) |
| `pkgs.nodejs-slim` | claude-mem plugin |
| `pkgs.bun` | claude-mem plugin |
| `pkgs.jq` | Settings merge in activation script |

---

## 2. Target State: omp-Native Layout

### 2.1 omp vs Claude Code Feature Mapping

| Claude Code | Oh My Pi | Migration Strategy |
|-------------|----------|--------------------|
| `~/.claude/CLAUDE.md` | `.omp/AGENTS.md` (native, priority 100) | **Move + rename**. Also discovered by omp's `claude` provider (priority 80), but native shadows it. |
| `~/.claude/settings.json` | `~/.omp/agent/config.yml` | **Retire the Nix-managed merge**. omp manages its own settings; the activation script becomes unnecessary. |
| `~/.claude/agents/` | `.omp/commands/` or extensions | **Port to slash commands** for simple agents; **extensions** for complex ones. |
| `~/.claude/commands/` | `.omp/commands/` | **Move**. Same markdown format. |
| `~/.claude/skills/` | `.omp/skills/` | **Move**. Same `<name>/SKILL.md` layout. |
| `PostToolUse` hooks | `~/.omp/agent/hooks/post/` | **Port**. omp hooks use different format. |
| Plugin system | Extensions + `omp plugin` CLI | **Retire**. claude-mem equivalent exists as omp's `memory.backend`. Other plugins (commit-commands, code-review, security-guidance) → port or drop. |
| Auth wrapper injection | Provider config in `config.yml` or env vars | **Remove wrapper**. omp natively supports `DEEPSEEK_API_KEY`, `ANTHROPIC_API_KEY` env vars and provider config. |
| Backend routing (DeepSeek) | Provider system | **Already configured**. omp auto-detects DeepSeek when `DEEPSEEK_API_KEY` is set. |

### 2.2 Target File Tree

```
~/.omp/agent/
├── config.yml                    # omp settings (replaces settings.nix)
├── AGENTS.md                     # user-level context (was CLAUDE.md)
├── RULES.md                      # sticky rules (new)
├── commands/                     # slash commands (was claude/commands/)
│   ├── plan.md
│   ├── review.md
│   ├── ship.md
│   └── dryrun.md
├── skills/                       # trigger-based skills (was claude/skills/)
│   ├── code-review-checklist/SKILL.md
│   ├── k8s-talos-ops/SKILL.md
│   ├── secrets-sops/SKILL.md
│   ├── shell-scripting/SKILL.md
│   ├── prek-hooks/SKILL.md
│   ├── verification-loop/SKILL.md
│   ├── context-budget/SKILL.md
│   └── iterative-retrieval/SKILL.md
└── hooks/
    └── post/
        └── nixfmt.sh             # post-write nix formatter

<nix-config>/.omp/
├── AGENTS.md                     # repo-level context
└── RULES.md                      # repo-level sticky rules
```

---

## 3. Migration Phases

### Phase 1: omp Context Files (least risk)

**Goal**: Establish `.omp/` as the primary context source.

**Actions**:
1. Create `~/.omp/agent/AGENTS.md` from current `CLAUDE.md`:
   - Update paths: `~/.claude/CLAUDE.md` → `.omp/AGENTS.md`
   - Update skill references: `~/.claude/skills/` → `.omp/skills/`
   - Remove plugin baseline section (replaced by omp config)
   - Remove wrapper/auth documentation (replaced by omp provider config)
2. Create `.omp/RULES.md` with hard constraints extracted from `CLAUDE.md`.
3. Create `<repo>/.omp/AGENTS.md` for repo-level context (currently auto-seeded from Nix store).
4. **Keep** `~/.claude/CLAUDE.md` as fallback during transition.

**Files touched**: New files only — no deletions yet.

### Phase 2: Port Skills (drop-in move)

**Goal**: Move all 8 skills to omp-native paths.

**Actions**:
1. Copy `claude/skills/*` → `~/.omp/agent/skills/*` (same layout).
2. **Audit each SKILL.md** for:
   - References to `~/.claude/` paths → update to `.omp/` equivalents
   - References to `claude` CLI → update to `omp`
   - References to `settings.json` fields → update to `config.yml` keys
3. Skills that are ECC-origin (`context-budget`, `iterative-retrieval`, `verification-loop`) may need re-scoping for omp's different tool set.
4. Delete `claude/skills/` from the Nix module.

**Risk**: Low. Skills are read-only markdown. If a skill references a tool omp doesn't have, it degrades gracefully.

### Phase 3: Port Commands (drop-in move)

**Goal**: Move slash commands to omp-native paths.

**Actions**:
1. Copy `claude/commands/*.md` → `~/.omp/agent/commands/*.md`.
2. Audit for tool name differences (omp uses `edit` not `Edit`, etc.).
3. Delete `claude/commands/` from the Nix module.

**Risk**: Low. Commands are injected markdown — format is identical.

### Phase 4: Port Agents → omp Equivalents

**Goal**: Replace claude-code sub-agents.

**Analysis**:
- **planner** → omp has a built-in plan mode (`--plan` flag, `/plan` auto-detected). The planner agent can become a slash command with plan-mode instructions.
- **reviewer** → omp has no direct sub-agent concept. Options:
  - Port as a slash command (`/review`) that injects review instructions
  - Port as a custom tool extension
  - Use omp's built-in `--advisor` mode with a review-focused `WATCHDOG.md`
- **infra-operator** → Port as a slash command with infrastructure safety rules.

**Decision**: Port all three as slash commands initially. Extensions can be added later if the simple command approach is insufficient.

**Actions**:
1. Port `planner.md` → `~/.omp/agent/commands/plan.md`
2. Port `reviewer.md` → `~/.omp/agent/commands/review.md`
3. Port `infra-operator.md` → `~/.omp/agent/commands/infra.md`
4. Delete `claude/agents/` from the Nix module.

### Phase 5: Port Hooks

**Goal**: Replace PostToolUse nixfmt hook.

**Actions**:
1. Create `~/.omp/agent/hooks/post/nixfmt.sh`:
   ```bash
   #!/usr/bin/env bash
   # Post-write hook: format .nix files with nixfmt
   file="$1"
   [[ "$file" == *.nix ]] || exit 0
   nixfmt "$file"
   ```
2. Remove PostToolUse hook from `settings.nix`.

**Risk**: Low. omp hooks are shell scripts — same execution model.

### Phase 6: Settings & Auth (structural change)

**Goal**: Retire the Nix-managed settings merge. Let omp manage its own config.

**Actions**:
1. Create `~/.omp/agent/config.yml` with equivalent settings:
   ```yaml
   modelRoles:
     default: deepseek/deepseek-v4-pro[1m]
     smol: deepseek/deepseek-v4-flash
     slow: deepseek/deepseek-v4-pro
   tools:
     approvalMode: yolo
     approval:
       bash: prompt
   memory:
     backend: off
   ```
2. Move auth from `ANTHROPIC_AUTH_TOKEN` file → `DEEPSEEK_API_KEY` env var (or omp's stored auth).
3. **Question**: Does omp support the DeepSeek Anthropic-compatible endpoint? Yes — omp has a `deepseek` provider with tool conversion (see `omp://toolconv/deepseek.md`). Set `DEEPSEEK_API_KEY` and configure `providers.deepseek.baseUrl` if needed.
4. Remove the entire wrapper (`claude-code-wrapped`) from the Nix module.
5. Remove the `home.activation.claudeSetup` script.
6. Remove `nodejs-slim` and `bun` from home.packages (were for claude-mem).

### Phase 7: Secrets Migration

**Goal**: Update sops secret from Claude-specific to omp-native.

**Actions**:
1. Rename sops secret `dev/claude/auth` → `dev/omp/auth` (or just use env vars).
2. Update `homes/soulwhisper/secrets/default.nix` and `secrets.sops.yaml`.
3. Update any `authFile` references.

### Phase 8: Nix Module Cleanup

**Goal**: Remove `modules.development.claude` entirely.

**Actions**:
1. Delete `homes/_modules/development/claude/` directory.
2. Update `homes/_modules/development/default.nix` — remove `./claude` import.
3. Update `homes/soulwhisper/default.nix` — remove `development.claude.*` lines.
4. Replace with a lightweight omp module if Nix-managed omp config is desired, or leave omp entirely self-managed.
5. Update `justfile` — replace `claude-bootstrap` with `omp-bootstrap` (or remove if omp self-bootstraps).
6. Update `docs/notes.md` — update the bootstrap reference.

### Phase 9: omp Bootstrap Recipe

**Goal**: Provide a `just omp-bootstrap` equivalent.

**Actions**:
```just
[doc('Bootstrap or update omp config (idempotent)')]
[script]
omp-bootstrap:
  # omp is installed via mise — verify it's available
  if ! command -v omp >/dev/null 2>&1; then
    echo "error: 'omp' not in PATH — run 'just {darwin,nixos} switch' first" >&2
    exit 1
  fi
  # Seed ~/.omp/agent/ from Nix store assets
  # (only if omp can't discover them from the repo's .omp/ itself)
  echo "omp bootstrap complete."
```

**Note**: Unlike claude-code, omp auto-discovers `.omp/` directories in the repo, so a bootstrap recipe may be unnecessary — omp just works from the repo root. The recipe would only be needed if there are user-level agents/skills to seed.

---

## 4. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| omp DeepSeek tool conversion differs from Anthropic-compatible protocol | Medium | High | Test `omp` with DeepSeek backend before switching. omp has `toolconv/deepseek.md` — verify it matches the current setup. |
| Skills reference Claude-specific tools that omp lacks | Medium | Low | Audit each skill. Most skills are tool-agnostic (process guidance). Specific tool names can be updated. |
| omp hooks format incompatible with current PostToolUse hooks | Low | Low | omp hooks are shell scripts — simpler than Claude's JSON hooks. |
| claude-mem equivalent missing in omp | Medium | Medium | omp has `memory.backend` with `local`, `hindsight`, `mnemopi` backends. Evaluate if any replace claude-mem's cross-session search. |
| `just claude-bootstrap` plugins have no omp equivalent | Low | Medium | `commit-commands`, `code-review`, `security-guidance` are Claude-specific plugins. omp has its own extension ecosystem — evaluate replacements or drop. |

---

## 5. Execution Order

```
Phase 1 (Context)   → Phase 2 (Skills) → Phase 5 (Hooks)
                   ↘                    ↘
Phase 3 (Commands) → Phase 4 (Agents) → Phase 6 (Settings/Auth)
                                         ↓
                                    Phase 7 (Secrets)
                                         ↓
                                    Phase 8 (Nix Cleanup)
                                         ↓
                                    Phase 9 (Bootstrap)
```

Phases 1-5 are **independent** and can run in parallel. Phase 6 depends on 1-5 being stable. Phases 7-8 are the final cutover.

---

## 6. Verification Checklist

- [ ] `omp` launches and discovers `.omp/AGENTS.md` context
- [ ] All 8 skills load via `skill://<name>`  
- [ ] All 4 commands appear as `/command` options
- [ ] `nixfmt` hook fires on `.nix` file writes
- [ ] DeepSeek backend works (tool calls round-trip correctly)
- [ ] `home-manager switch` succeeds without claude module
- [ ] `just claude-bootstrap` is gone (or renamed)
- [ ] sops secret `dev/claude/auth` is migrated
- [ ] `nix flake check` passes
- [ ] CI `nix-build` workflow passes

---

## 7. Open Questions

1. **DeepSeek provider in omp**: Does omp's DeepSeek tool conversion handle the same Anthropic-compatible protocol we currently use? Need to test `DEEPSEEK_API_KEY` + `DEEPSEEK_BASE_URL=https://api.deepseek.com/anthropic`.

2. **claude-mem replacement**: omp's `memory.backend` options (local, hindsight, mnemopi) — which one provides cross-session search comparable to claude-mem's GIN-indexed observation search?

3. **Auth file vs env var**: Currently auth is read from a sops-managed file. Does omp support reading API keys from a file, or must we switch to env vars?

4. **Nix-managed omp config**: Should we Nix-manage `~/.omp/agent/config.yml` (home-manager `home.file`), or leave omp fully self-managed? The current approach for claude-code is a hybrid (Nix manages the fragment, CLI owns the rest). omp's config merge model (`defaults ← global ← project ← CLI overlays`) is already layered — adding Nix management may conflict.

5. **Per-repo `.omp/` vs global**: The current claude-code setup seeds `CLAUDE.md`, agents, commands, and skills from the Nix store into `~/.claude/`. With omp, do we place these in the repo's `.omp/` (project-level) or `~/.omp/agent/` (user-level)? Recommendation: project-level `.omp/` for repo-specific config, user-level `~/.omp/agent/` for cross-repo skills.
