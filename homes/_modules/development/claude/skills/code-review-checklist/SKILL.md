---
name: code-review-checklist
description: Use whenever reviewing a diff, PR, or set of staged changes — invoked automatically by the `reviewer` agent. Walks the project's checklist for correctness, security, idiom, and review hygiene across code, Nix, shell, and infra YAML.
---

# Code review checklist

The reviewer agent reads this skill on every invocation. The checklist is
ordered by severity ceiling — items earlier in the list, when violated, are
usually higher severity.

## 1. Secrets and credentials (Critical floor)

- [ ] No hardcoded token, API key, password, JWT secret, or private key
      anywhere in the diff.
- [ ] No new file under a path that should be sops-encrypted but isn't
      (e.g. `secrets/foo.yaml` instead of `secrets/foo.sops.yaml`).
- [ ] No relaxation of the `permissions.deny` list in `settings.json`
      (sops/age/kubeconfig denies must stay).
- [ ] No `--no-verify` past pre-commit. If `gitleaks` was triggered,
      investigate, don't bypass.

## 2. Destructive surface

- [ ] No new shell-out to `rm -rf`, `kubectl delete`, `helm uninstall`,
      `talosctl reset`, or `nix-collect-garbage` without being gated by
      `permissions.ask` (which already covers these — the check is that no
      one bypassed via `bash -c '…'`).
- [ ] Migrations and CRD changes have a documented rollback path.
- [ ] Anything that runs at activation (NixOS / home-manager activation
      scripts) is idempotent on second run.

## 3. Correctness

- [ ] The diff does what the commit/PR title says — no unrelated drive-bys.
- [ ] Inputs are validated where they cross a trust boundary (user input,
      network response, file contents). Failure modes are explicit.
- [ ] Errors are handled, not silenced. `try/except Exception: pass` and
      `2>/dev/null || true` are Medium findings unless justified inline.
- [ ] Off-by-one, empty-collection, and null cases are covered.
- [ ] Concurrency: any shared state has explicit synchronization or is
      documented as single-writer.

## 4. Tests

- [ ] New behavior has a test; bug fixes have a regression test.
- [ ] The test actually asserts the behavior — a test with no assertions or
      with `assert True` is Medium.
- [ ] Tests run by default in the project's checker (`just check`,
      `nix flake check`). If they don't run, they don't exist.

## 5. Nix-specific

- [ ] Module additions use `mkIf cfg.enable` and don't pollute the
      top-level when disabled.
- [ ] No IFD (`builtins.readFile` of a build output, `fetchGit` of a private
      repo) inside `config = …`.
- [ ] No `home.file` for a file the consuming CLI writes to at runtime
      (EROFS trap). Use `home.activation` + jq merge instead.
- [ ] `nixfmt` / `nixfmt-tree` clean. Pre-commit runs this; if the diff
      isn't formatted, something's broken in the hook chain.

## 6. Shell-specific

- [ ] `set -euo pipefail` at the top of new scripts.
- [ ] All variable expansions quoted unless intentional.
- [ ] `shellcheck` clean, or has a `# shellcheck disable=…` with a
      one-line reason.
- [ ] Re-running the script produces the same end state (idempotent).

## 7. Kubernetes / Talos manifests

- [ ] No bare `latest` tag on images going into anything stateful.
- [ ] Resource requests/limits set, or explicitly documented as omitted.
      Memory limits in particular — OOM kill is silent.
- [ ] Pod security: no `privileged: true`, no `hostNetwork: true`, no
      `hostPID: true` unless justified.
- [ ] Secrets referenced via `secretKeyRef`, not inline.

## 8. Style and review hygiene

- [ ] Conventional commit message (`feat:`, `fix:`, `refactor:`, …).
- [ ] No new dependency without a one-line "why this one" in the PR
      description.
- [ ] Comments explain *why*, not *what* — the code says what.
- [ ] No dead code, commented-out blocks, or `// TODO without ticket`.
- [ ] Docs updated when the user-facing contract changed (CLI flags,
      module options, env vars).

## Severity defaults

Treat the first item in each numbered section as the floor severity for
that section:

- §1, §2 → Critical/High; do not approve.
- §3, §5, §6, §7 → High to Medium depending on impact.
- §4 → Medium typically; High when a regression test for a real bug is
  missing.
- §8 → Low usually, Medium when it actively confuses future readers.
