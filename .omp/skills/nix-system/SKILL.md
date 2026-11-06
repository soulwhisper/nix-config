---
name: nix-system
description: Use whenever the request involves NixOS or nix-darwin hosts, home-manager, nix flakes, rebuilding/switching a system, generations, secrets via sops-nix/age (*.sops.*, *.age, ~/.config/{sops,age}), or Chinese/GBK filename and encoding issues. Trigger for casual mentions like "rebuild", "switch", "update the flake", "add a module", "add an env var/secret", "GBK/Chinese filename", or naming a host.
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

## Bumping hermes-agent

`hermes-agent` is pinned by a tarball input at an exact tag commit, plus a
display stamp in the wrapper module. Both must move together:

- `flake.nix` → `inputs.hermes-agent.url` (`archive/<sha>.tar.gz`)
- `hosts/_modules/nixos/services/hermes-agent/default.nix` → `version`,
  `rev`, `lastModified`
- `flake.lock` → regenerate, never hand-edit

```bash
tag=$(gh api repos/NousResearch/hermes-agent/releases/latest --jq .tag_name)
sha=$(git ls-remote https://github.com/NousResearch/hermes-agent "refs/tags/$tag^{}" | cut -f1)
epoch=$(date -u -d "$(gh api "repos/NousResearch/hermes-agent/commits/$sha" --jq .commit.committer.date)" +%s)
# edit flake.nix URL and the three module constants with $tag/${tag#v}, $sha, $epoch
nix flake update hermes-agent
nix build .#nixosConfigurations.nix-ops.config.services.hermes-agent.package
./result/bin/hermes --version
```

Rules:

- Keep upstream's locked nixpkgs. Its `pm-packages.nix` patches patchelf
  0.19.2; nixos-26.05 has 0.15.2 and the patch does not apply.
- The existing `update-flake-lock` workflow cannot chase tags; this pin is
  manual unless a tag-bump workflow is added.
- Dashboard basic auth uses the bundled `dashboard_auth/basic` provider:
  username `admin`; the password is read from the gitignored
  `temp/admin.pass`, hashed with the package's `hash_password`, and stored as
  the sops secret `services/hermes/dashboard_password_hash`. The signing
  secret is `services/hermes/dashboard_secret`. Both are rendered through
  `hermes-dashboard-env` into `HERMES_HOME/.env`. The plaintext never enters
  sops or the Nix store.
- To rotate: write the new password to `temp/admin.pass`, compute the scrypt
  hash with the package venv's Python, `sops set` the hash, then restart
  `hermes-backend.service`. The soulwhisper PAM secret is a yescrypt hash and
  cannot be used as the dashboard credential.

## Chinese / GBK filenames (agent hint)

NixOS hosts here use a UTF-8 locale (`en_US.UTF-8`). Files from Chinese
Windows or legacy zip/tar downloads often carry **GBK/GB18030 filename
bytes**, which are not valid UTF-8. Symptoms: `ls` shows `M-...`/`\xNN`
escapes, tools say `illegal byte sequence`, or an agent sees replacement
characters and cannot open the path.

Do not "fix" this with a host-wide `zh_CN` locale, CJK fonts, or SSH
`AcceptEnv`/`SendEnv`:

- `zh_CN.UTF-8` still rejects GBK filename bytes;
- `zh_CN.GB18030` decodes them but emits GB18030, which breaks UTF-8
  terminals and JSON;
- fonts only affect glyph rendering, and terminal fonts are client-side;
- SSH locale propagation does not convert filename bytes.

Normalize at the ingestion boundary instead:

```python
python3 - <<'PY'
import os
for b in os.listdir(b'.'):
    if b.lower().endswith(b'.docx'):
        try:
            b.decode('utf-8')
        except UnicodeDecodeError:
            os.rename(b, b.decode('gbk').encode('utf-8'))
PY
```

For transfers, `rsync --iconv=GB18030,UTF-8` converts names; `scp`/`sftp`
preserve bytes, so convert after download or at the source. DOCX contents
are UTF-8 inside the zip/XML; usually only the filename is GBK.

**Agent hint:** when a path has escaped/invalid bytes, decode/rename it to
UTF-8 before reading or passing it to a tool. Do not propose a NixOS
locale/font change as the fix; the host already runs UTF-8.

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
