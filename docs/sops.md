# SOPS

## Encrypt / Decrypt

```shell
export SOPS_AGE_KEY_FILE=keys.txt

sops --verbose -i -d secrets.sops.yaml
sops --verbose -i -e secrets.sops.yaml
```

## Template

- all values should not have spaces/quotes;

```shell
sops edit secrets.sops.yaml
cat -p secrets.sops.yaml
```

```yaml
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
  cloudflare:
    auth: |
      CLOUDFLARE_EMAIL={cf-email}
      CLOUDFLARE_DNS_API_TOKEN={cf-dns-api-token}
  proxy:
    subscription: |
      SUBSCRIPTION={sub-url}
  easytier:
    auth: |
      [network_identity]
      network_name={easytier-network-name}
      network_secret={easytier-network-secret}
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
