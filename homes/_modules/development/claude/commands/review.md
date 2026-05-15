---
description: Invoke the `reviewer` agent on the current uncommitted (or staged) diff. Runs project checks, walks the code-review checklist skill, reports findings by severity. Always do this before `git push`.
---

# /review

Invokes the **reviewer** agent. The reviewer:

1. Runs `git diff` to see the changed range.
2. Reads each touched file in full (the bug is often outside the hunk).
3. Runs `just check` / `nix flake check` / `prek run --all-files` if
   available.
4. Walks `~/.claude/skills/code-review-checklist/SKILL.md`.
5. Reports Critical / High / Medium / Low with file:line and suggested fix.

Hard floor: no diff that adds a credential, loosens the sops/age deny list,
or weakens a destructive-command `ask` rule will be approved.
