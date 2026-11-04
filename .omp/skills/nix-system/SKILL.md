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

- `just nixos build <HOST> <FULL_REVISION> [--builder ssh://user@builder]`
- `just nixos plan <HOST> <TARGET> <FULL_REVISION> <SYSTEM> <PLAN>`
- `just nixos diff <PLAN>` then `just nixos deploy <PLAN> <REVIEWED_DEPLOY_APPROVAL>`
- `just nixos rollback <PLAN> <REVIEWED_ROLLBACK_APPROVAL>`
- `just darwin initialize|build|switch <HOST>`
- `just lint` — prek across the repo

Mutation discipline: build the exact clean Git revision and inspect the closure
diff before activation. NixOS plans bind target, revision, system path and previous
profile, with distinct deploy/rollback approvals. Darwin retains its existing
generation rollback workflow. Activation remains gated by omp's approval settings.

## Deployment boundaries

- NixOS recipes delegate to `deploymentctl`; there is no old local-only switch
  signature. Keep plans outside the clean checkout and never select `nix-dev` as
  an implicit builder. Darwin controllers need an explicit Linux builder or an
  exact prebuilt closure.
- There is still no NixOS `initialize`/bootstrap recipe. Do not improvise remote
  bootstrap commands without a separately reviewed process.
- A generation rollback does not reverse database migrations or CA revocations.
  Use the separately approved recovery workflow when persistent state is involved.
- `nix-dev` enables PKI/Forgejo but requires real issuer SOPS values before any
  production build/switch. See `docs/corporate-services.md`; never bypass the
  missing-secret guard or generate a substitute production authority.

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
