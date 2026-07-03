---
description: Produce a diff/preview of a pending infra change without applying it. Wrapper around the common `*-diff`/`*-build` commands across Nix, kubectl, helm, and Talos.
---

# /dryrun

Show me what a pending change would do, **without applying it**. Pick the
right tool for the target:

| Target | Command |
|--------|---------|
| NixOS / nix-darwin | `nixos-rebuild build` then `nvd diff /run/current-system result` (fallback: `nix store diff-closures`) |
| Home-manager | `home-manager build` then `nvd diff` |
| kubectl manifest | `kubectl diff -f <file>` (or `kustomize build … \| kubectl diff -f -`) |
| Helm release | `helm diff upgrade <release> <chart> -n <ns> -f values.yaml` |
| Talos machine config | `talosctl -n <node> diff` |
| Terraform / OpenTofu | `<tool> plan` |

If multiple targets are in play, run them in series, label each section, and
end with a one-paragraph summary of the cumulative blast radius.

No mutating commands. If a follow-up `/ship` is appropriate, suggest it
but do not run it.
