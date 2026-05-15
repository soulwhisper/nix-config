---
description: Invoke the `planner` agent to produce a written, reviewable plan before any code or infra change. Required for multi-file work, anything touching infra, and anything with ambiguous scope.
---

# /plan

Hand the current request to the **planner** agent. The planner restates the
request, lists open questions, identifies risks, and produces a numbered
plan with per-step verify/rollback. **No edits happen until the plan is
accepted.**

Use this whenever the next move isn't obvious in one read.
