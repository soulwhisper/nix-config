---
description: Invoke the `reviewer` agent on the current uncommitted (or staged) diff. Walks the code-review-checklist skill, reports findings by severity.
---

# /review

Invoke the **reviewer** agent. The reviewer:

1. Runs `git diff` to see the changed range.
2. Reads each touched file in full (the bug is often outside the hunk).
3. Runs `just check` / `nix flake check` / `prek run --all-files` if
   available.
4. Reads `skill://code-review-checklist` and walks every section.
5. Reports Critical / High / Medium / Low with file:line and suggested fix.

Hard floor: no diff that adds a credential, loosens sops/age protection,
or weakens destructive-command gating will be approved.
