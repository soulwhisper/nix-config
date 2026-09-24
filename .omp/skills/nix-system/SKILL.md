---
name: nix-system
description: Use whenever the request involves NixOS or nix-darwin hosts, home-manager, nix flakes, rebuilding/switching a system, generations, or secrets via sops-nix/age (*.sops.*, *.age, ~/.config/{sops,age}). Trigger for casual mentions like "rebuild", "switch", "update the flake", "add a module", "add an env var/secret", or naming a host.
---

# Nix system operations (nix-config)

Flake managing NixOS hosts, nix-darwin hosts, and home-manager. Solo
operator; a wrong `switch` is a pager event.

## Discover before acting

```bash
ls hosts/ homes/                    # actual host + home inventory
cat flake.nix                       # inputs, outputs wiring
just --list                         # build/switch/lint recipes
```

Hosts split by OS under `hosts/`; shared modules under `hosts/_modules/`
and `homes/_modules/`. Don't hardcode host names from memory — read them.

## Build & switch workflows

Use the just recipes (`.justfiles/nixos.just`, `.justfiles/darwin.just`):

- `just nixos build|switch <HOST>`
- `just darwin initialize|build|switch <HOST>`
- `just lint` — prek across the repo

Mutation discipline: build + diff before switch (`nvd diff
/run/current-system result`), state the rollback (`nixos-rebuild
--rollback` / generation select), confirm, then apply. Activation commands
are gated by omp's approval settings.

## Known gaps in the current NixOS tooling — say so, don't improvise

- `nixos.just` has only `build`/`switch`, local-only. There is **no
  `initialize`/bootstrap recipe** (darwin has one), **no remote deploy**
  (`--target-host` to e.g. nix-dev), and **no rollback/dry-run recipe**.
- If a task needs one of those, name the gap and propose extending
  `nixos.just` as its own change — do not hand-run ad-hoc equivalents
  against a host without surfacing it.

## Secrets (sops-nix)

This repo uses **sops-nix** with **age** keys. Secrets are encrypted in
the repo and decrypted at activation to tmpfs paths under
`/run/user/<uid>/secrets/<name>`.

### Iron rules

1. **Never echo, log, paste, or `cat` a decrypted secret.** Not in chat,
   not in `git diff` output, not in a comment "for context".
2. **Never propose moving a secret out of sops** because it's "easier".
   Easier is the failure mode.
3. **Bare token files only.** Sops secrets here store *just the token*, no
   `KEY=value` prefix. Wrappers compose env vars, keeping the sops file
   reusable across providers.

### Adding a new secret

```bash
# 1. Open the encrypted file in $EDITOR — sops handles decrypt/re-encrypt.
sops <path>/secrets.sops.yaml

# 2. Reference it from a host's home-manager config:
#    sops.secrets.<name> = { sopsFile = ./secrets.sops.yaml; };
#    Then use config.sops.secrets.<name>.path

# 3. Build, switch, then verify the runtime path exists:
ls -l /run/user/$UID/secrets/<name>     # owner = your user, mode 0400
```

The decrypted file path is what services and wrappers reference — never
read or copy its contents into other files.

### Plugging a secret into a service

Pattern: pass the *path* to a wrapper or systemd unit; the wrapper reads
the path at runtime.

```nix
# Good — the secret path is the public contract.
modules.development.omp = {
  enable   = true;
  authFile = config.sops.secrets.deepseek_api_key.path;
};

# Bad — leaks the literal token into the Nix store world-readable.
home.sessionVariables.DEEPSEEK_API_KEY =
  builtins.readFile config.sops.secrets.deepseek_api_key.path;
```

### Rotating a secret

1. `sops <file>` and replace the value.
2. Activate (`home-manager switch`) on every host that consumes it —
   sops-nix re-decrypts at activation.
3. If the service caches the value (reads once at startup), restart it.
   For `omp`, that's exiting and re-launching.
4. Audit `git log -p <encrypted file>` — only ciphertext may change.

### Pre-commit safety net

`prek` runs a secret scanner at pre-commit (see the `code-review` skill).
Never bypass with `--no-verify`; investigate. False positives are usually
example values — replace with `REDACTED` or allowlist with a path scope.

### Cross-check before committing

```bash
git diff --cached -- '*.sops.*' '*.age'
# Only re-encrypted ciphertext, never plaintext fields.
```

### If you suspect a leak

1. Treat as compromised. Rotate at the source **first**.
2. Then sops-edit the encrypted file, switch, restart consumers.
3. Do not rewrite git history to "hide" the leak — assume it's harvested.
   Rotation > rewriting.
