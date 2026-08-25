# Secrets & SOPS

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) using age.
Encrypted files match `*.sops.yaml`; `.sops.yaml` at the repository root defines
creation rules and key paths.

## Workflow

```shell
# point sops at the age key (adjust path, see "Key placement")
export SOPS_AGE_KEY_FILE=keys.txt

# decrypt in place
sops --verbose -i -d secrets.sops.yaml

# encrypt in place
sops --verbose -i -e secrets.sops.yaml
```

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
    auth: { atuin-key } # base64-encoded
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
  hass-sgcc:
    auth: |
      PHONE_NUMBER={sgcc-account}
      PASSWORD={sgcc-password}
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
