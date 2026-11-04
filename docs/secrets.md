# Secrets & SOPS

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) using age.
Encrypted files match `*.sops.yaml`; `.sops.yaml` at the repository root defines
creation rules and key paths.

## Workflow

```shell
# Point SOPS at the existing age identity; never print its contents.
export SOPS_AGE_KEY_FILE="$HOME/.config/age/keys.txt"

# Edit through SOPS; only encrypted content is written back to the repository.
sops hosts/nix-dev/secrets.sops.yaml
```

Do not decrypt repository files in place or commit plaintext staging files.
Pass secret paths to services, not `builtins.readFile` results.

Corporate CA material is provisioned as one validated issuer set through the
controller tools. The enabled `nix-dev` configuration deliberately has no dummy
PKI values: populate the four declared `pki/*` values before activation.
See [the corporate services runbook](corporate-services.md). Root signing keys
and root-CA state must not be encrypted to the deployed host's age identity.

## Key placement

age private keys are imported manually per machine:

| State | Path |
|---|---|
| macOS before migration | `/Users/<username>/Library/Application Support/sops/age/keys.txt` |
| macOS after migration | `/Users/<username>/.config/age/keys.txt` |

## Conventions

- Scalar values contain no spaces and no quotes.
- Multi-line values are env files or tool config fragments; the consuming
  module reads them via `config.sops.secrets."<path>".path`.
- Placeholder syntax below: `{placeholder}`.

## Template

Structure of `secrets.sops.yaml` per host:

```yaml
# defaults
dev:
  deepseek:
    key: { DEEPSEEK_API_TOKEN }
shell:
  atuin:
    auth: { atuin-key }
```

Full example covering all known keys:

```yaml
alerting:
  pushover:
    auth: |
      PUSHOVER_TOKEN={pushover-application-token}
      PUSHOVER_KEY={pushover-user-key}
apps:
  default:
    auth: { default-password }
  fvtt:
    auth: |
      FOUNDRY_ADMIN_KEY={fvtt-admin-password}
      FOUNDRY_USERNAME={fvtt-account-username}
      FOUNDRY_PASSWORD={fvtt-account-password}
  moviepilot:
    auth: |
      AUTH_SITE="iyuu,haidan"
      IYUU_SIGN=""
      HAIDAN_ID=""
      HAIDAN_PASSKEY=""
backup:
  restic:
    encryption: { restic-encryption-password }
    endpoint: { restic-repository-s3 }
    auth: |
      AWS_ACCESS_KEY_ID={s3-access-key}
      AWS_SECRET_ACCESS_KEY={s3-access-secret}
networking:
  bind:
    auth: { external-key-secret }
  cloudflare:
    auth: |
      CLOUDFLARE_EMAIL={cf-email}
      CLOUDFLARE_DNS_API_TOKEN={cf-dns-api-token} # permission: CF-API:ZONE:DNS:EDIT
  proxy:
    subscription: |
      name1:url1
      name2:url2
  easytier:
    auth: |
      [[peer]]
      uri={easytier-peer}
      peer_public_key={easytier-peer-pubkey}
      [network_identity]
      network_name={easytier-network-name}
      network_secret={easytier-network-secret}
      [secure_mode]
      enabled=true
      local_private_key={easytier-local-prikey}
      local_public_key={easytier-local-pubkey}
storage:
  minio:
    auth: |
      MINIO_ROOT_USER={minio_root_user}
      MINIO_ROOT_PASSWORD={minio_root_pass}
  versitygw:
    auth: |
      ROOT_ACCESS_KEY={root_user}
      ROOT_SECRET_KEY={root_pass}
users:
  soulwhisper:
    password: { hashed-password }
```
