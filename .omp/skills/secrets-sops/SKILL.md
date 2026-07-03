---
name: secrets-sops
description: Use whenever the work touches secrets, tokens, API keys, sops, age, or any file matching `*.sops.*`, `*.age`, or paths under `~/.config/{sops,age}`. Trigger even when the user is just "adding an env var" — many env vars are credentials in disguise. Especially relevant when wiring services to sops-nix.
---

# Secrets & sops-nix

This config uses **sops-nix** with **age** keys. Secrets are encrypted in
the repo and decrypted at activation to tmpfs paths under
`/run/user/<uid>/secrets/<name>`.

## Iron rules

1. **Never echo, log, paste, or `cat` a decrypted secret.** Not in chat,
   not in `git diff` output, not in a comment "for context".
2. **Never propose moving a secret out of sops** because it's "easier".
   Easier is the failure mode.
3. **Bare token files only.** Sops secrets in this repo store *just the
   token*, no `KEY=value` prefix. Wrappers compose env vars. This keeps the
   sops file generic enough to be reusable across providers.

## Adding a new secret

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

## Plugging a secret into a service

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

The first form keeps the token in tmpfs, owned by the user, never on disk.
The second writes it to a store path that's globally readable.

## Rotating a secret

1. `sops <file>` and replace the value.
2. Activate (`home-manager switch`) on every host that consumes it —
   sops-nix re-decrypts at activation.
3. If the service caches the value (reads it once at startup),
   restart it. For `omp`, that's exiting and re-launching.
4. Audit `git log -p <encrypted file>` to confirm only the ciphertext
   changed — never the plaintext.

## Pre-commit safety net

`prek` has `gitleaks` hooked at pre-commit. If gitleaks ever complains, do
not bypass with `--no-verify`. Investigate. The most common false-positive
trigger is example values that look like real keys; either replace with
`REDACTED` or extend the gitleaks allowlist with a specific path scope.

## Cross-check before committing

```bash
# What did I actually change?
git diff --cached -- '*.sops.*' '*.age'

# The diff should be only re-encrypted ciphertext, never plaintext fields
# you intended to add elsewhere.
```

## If you suspect a leak

1. Treat the secret as compromised. Rotate it at the source (DeepSeek
   console, GitHub PAT settings, …) **first**.
2. Then sops-edit the encrypted file with the new value, switch, restart.
3. Do not rewrite git history to "hide" the leak — assume it's already
   harvested. Rotation > rewriting.
