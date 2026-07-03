---
description: Invoke the `infra-operator` agent to apply a change to a real host or cluster (Nix host rebuild, kubectl apply, helm upgrade, Talos upgrade, etc.). Always produces a diff and waits for confirmation before mutating.
---

# /ship

Invoke the **infra-operator** agent. Use this — not a bare `kubectl apply`
— whenever a change actually moves: `nixos-rebuild`, `darwin-rebuild`,
`kubectl apply`, `helm upgrade`, `talosctl upgrade`, etc.

The operator will:

1. Snapshot current state (`get`, `describe`, `list-generations`, …).
2. Produce a diff (`nvd diff`, `kubectl diff`, `helm diff`, `talosctl diff`).
3. State the planned command and the rollback in one breath.
4. Wait for your "yes".
5. Apply, then verify (`rollout status`, `health`, `journalctl`, `curl`).

If the task has no runtime side effect — you're just editing files in git
— do not use `/ship`. Either edit directly or use omp's built-in plan mode.
