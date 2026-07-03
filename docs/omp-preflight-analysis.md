# OMP Migration: Pre-Flight Analysis

**Date**: 2026-07-03

---

## Part 1: Relocate mise config from shell → development

### Current state

`homes/_modules/shell/utilities/default.nix:35-60` defines `programs.mise` with:

| Tool | Purpose | Category |
|------|---------|----------|
| `prek` | Pre-commit runner | Development |
| `oh-my-pi` | AI coding agent | Development |
| `rtk` | Token-optimized CLI proxy | Development |
| `flate` | K8s operations (conditional) | Development |

All four are **development tooling**, not shell utilities. They belong in `modules.development`.

### Plan

1. Create `homes/_modules/development/mise.nix` — extract `programs.mise` block.
2. Update `homes/_modules/development/default.nix` — add `./mise` import.
3. Remove mise block from `homes/_modules/shell/utilities/default.nix`.
4. Verify `home-manager switch` still installs mise + tools.

### New file: `homes/_modules/development/mise.nix`

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.development;
in {
  config = lib.mkIf cfg.enable {
    # mise — runtime version manager; preferred over direnv
    programs.mise = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      globalConfig = {
        env = {
          "RTK_TELEMETRY_DISABLED" = "true";
        };
        settings = {
          experimental = true;
          disable_hints = ["*"];
          always_keep_download = false;
          always_keep_install = false;
          idiomatic_version_file_enable_tools = ["node" "python" "go" "rust"];
        };
        tools = {
          prek = "latest";
          "github:can1357/oh-my-pi" = "latest";
          # rtk init: 'rtk init -g --agent pi' for omp, 'rtk init -g' for claude-code
          "github:rtk-ai/rtk" = "latest";
        } // lib.optionalAttrs (config.modules.kubernetes.enable) {
          "github:home-operations/flate" = "latest";
        };
      };
    };
  };
}
```

**Rationale**: Gated behind `modules.development.enable` (already `true` in home config). Mise is a development tool; keeping it in `shell/utilities` was a misplacement from when the development module didn't exist.

---

## Part 2: OMP Requirements & Claude Config Evaluation

### 2.1 Does omp need a Nix-native package?

**Answer: No. Mise is sufficient.**

| Factor | Assessment |
|--------|------------|
| nixpkgs availability | **Not in nixpkgs**. Issue [#596](https://github.com/can1357/oh-my-pi/issues/596) shows community interest but no upstream package. |
| Distribution | npm (`@oh-my-pi/pi-coding-agent`), GitHub releases, Homebrew. Mise installs from GitHub releases. |
| Build complexity | Bun monorepo with native Rust crates. A Nix package would need `fetchFromGitHub` + `bun build` + native deps. |
| Version management | Renovate already auto-updates mise plugins. No benefit from flake-input pinning. |
| Cache benefit | None — omp isn't in the Nix binary cache. Building locally would be slower than mise's prebuilt binary fetch. |

**Recommendation**: Keep `mise` as the installer. If a future nixpkgs PR lands, we can add a `pkgs.unstable.oh-my-pi` fallback with `lib.mkIf`.

### 2.2 Skill Portability Audit

| Skill | Status | Changes Needed |
|-------|--------|----------------|
| `code-review-checklist` | **Portable** | Replace `settings.json` deny references → omp `config.yml` `tools.approval`. Remove reviewer-agent invocation note. |
| `context-budget` | **Partially portable** | Methodology is generic but component taxonomy (agents → extensions, MCP → same, skills → same) differs. Rewrite component inventory section. |
| `iterative-retrieval` | **Portable** | Generic pattern. No changes needed beyond tool name normalization. |
| `k8s-talos-ops` | **Portable** | Replace `permissions.deny` references → omp's `tools.approval` model. Replace `/ship` → omp command equivalent. |
| `prek-hooks` | **Portable** | Replace `PostToolUse` hook reference → omp `hooks/post/` format. |
| `secrets-sops` | **Portable** | Replace `settings.json` → `config.yml`. Replace `modules.development.claude-code` → omp auth pattern. Replace "restart claude" → "restart omp". |
| `shell-scripting` | **Portable** | Update `just claude-bootstrap` example → `just omp-bootstrap` or remove. |
| `verification-loop` | **Partially portable** | ECC-origin, references Claude Code `/verify` command. Replace with omp equivalents. |

**Verdict**: 6 of 8 skills are directly portable with minor text edits. 2 need moderate rewriting. Zero are irreplaceable.

### 2.3 Plugin Irreplaceability

| Plugin | Status | Replacement |
|--------|--------|-------------|
| `commit-commands` | **Irreplaceable as plugin** | omp has no plugin for conventional commits. Functionality is available as a **slash command** (inject commit-formatting instructions). Low priority — user writes commits manually. |
| `code-review` | **Replaceable** | The `code-review-checklist` skill covers the same content. The plugin was the *runner*; omp can invoke the skill directly as a command. |
| `security-guidance` | **Irreplaceable as plugin** | omp has no security-guidance plugin. The `code-review-checklist` skill §1 and §2 cover secrets and destructive surface. A dedicated `security-review` skill could fill the gap. |
| `claude-mem` | **Replaceable** | omp's `memory.backend` with `hindsight` or `mnemopi` provides cross-session memory. Evaluation needed on feature parity (search across sessions, observation types). |

**Verdict**: 1 plugin is truly irreplaceable in current form (`commit-commands`), but the functionality is non-critical. The other 3 have omp-native replacements.

### 2.4 Agent Replaceability

| Agent | omp Equivalent | Notes |
|-------|---------------|-------|
| `planner` | Built-in `--plan` mode | omp's plan mode is more featureful. The planner agent becomes a slash command for plan-mode invocation. |
| `reviewer` | `--advisor` + `WATCHDOG.md` | omp's advisor watches every turn. A review-focused `WATCHDOG.md` can replicate "review on demand" behavior. |
| `infra-operator` | Slash command | Safety rules become a command + `RULES.md` sticky rules. |

**Verdict**: All three agents have omp-native equivalents. Zero are irreplaceable.

### 2.5 Should omp config be Nix-managed?

**Answer: Yes, with the same hybrid approach as claude-code.**

The community module from [azais-corentin](https://github.com/can1357/oh-my-pi/issues/596#issuecomment-2909904164) demonstrates a clean pattern:

```nix
oh-my-pi = {
  enable = true;
  settings = { ... };     # → ~/.omp/agent/config.yml (read-only symlink)
  skills = { ... };       # → ~/.omp/agent/skills/
  commands = { ... };     # → ~/.omp/agent/commands/
  rules = { ... };        # → ~/.omp/agent/rules/
};
```

**However**, this has the same EROFS trap as claude-code: `config.yml` is **writable at runtime** (omp writes state, plugin config, session metadata). A read-only symlink breaks this.

**Recommended approach** (same as current claude-code design):

| Concern | Management | Rationale |
|---------|-----------|-----------|
| **Provider config** (API keys, base URLs) | **Env vars** or sops-managed auth file | Never in Nix store. omp reads `DEEPSEEK_API_KEY` natively. |
| **Model roles** | `~/.omp/agent/config.yml` (omp-managed) | Changes at runtime. Nix would clobber. |
| **Skills, commands, rules** | Nix `home.file` (seed-on-absent) | Declarative, version-controlled. Same seed-on-absent logic as current claude-code module. |
| **Hooks** | Nix `home.file` to `.omp/agent/hooks/` | Same as current `PostToolUse` hooks. |
| **MCP servers** | `~/.omp/agent/mcp.json` (omp-managed) | Changes at runtime. |

**Design**: A thin omp Nix module that seeds skills, commands, rules, and hooks — but does NOT manage `config.yml`. The `omp` CLI owns its own settings. This mirrors the current `claude-code-wrapped` design without the wrapper complexity (no auth injection needed — omp uses env vars natively).

### 2.6 Summary Matrix

| Component | Count | Portable | Needs Rewrite | Irreplaceable |
|-----------|-------|----------|---------------|---------------|
| Skills | 8 | 6 | 2 | 0 |
| Plugins | 4 | 0 (as plugins) | 3 (as omp features) | 1 (low priority) |
| Agents | 3 | 0 (as agents) | 3 (as commands/modes) | 0 |
| Commands | 4 | 4 | 0 | 0 |
| **Total** | **19** | **10** | **8** | **1** |

**Conclusion**: The migration is viable. One plugin (commit-commands) has no direct omp equivalent but is non-critical. All skills, agents, and commands migrate cleanly. A Nix-native omp package is unnecessary — mise handles installation. A thin Nix module for managing skills/commands/hooks is worth building (same seed-on-absent pattern as current claude-code module).
