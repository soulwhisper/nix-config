# Documentation

Operating docs for this repository. Code lives in `hosts/`, `homes/`, and `lib/`;
this directory explains how to operate and reason about it.

| Document | Scope |
|---|---|
| [architecture.md](architecture.md) | Interactive flake architecture diagram and regeneration notes |
| [secrets.md](secrets.md) | SOPS workflow, age-key placement, secret template conventions |
| [services.md](services.md) | Per-service operational notes and the port registry |
| [runbook.md](runbook.md) | Commands for deploy, troubleshooting, and maintenance |
| [decisions.md](decisions.md) | Rejected/deprecated components and chosen alternatives |
| [terminal.md](terminal.md) | Terminal environment: zellij, Ghostty, fonts, input method |
| [spec-desktop-support.md](spec-desktop-support.md) | Design spec for NixOS desktop support |

## Conventions

- One document per concern; new topics get a new file and an index row here.
- Commands assume the repository task runner (`just`) where one exists;
  raw `shell` blocks are copy-paste ready.
- Placeholder syntax in examples is `{placeholder}` unless the tool defines its own.
