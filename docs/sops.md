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
apps:
    hass-sgcc:
        auth: |
            PHONE_NUMBER={sgcc-account}
            PASSWORD={sgcc-password}
backup:
    restic:
        encryption: {restic-encryption-password}
        endpoint: {restic-repository-s3}
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
            SUB_1={sub-url-1}
            SUB_2={sub-url-2}
    easytier:
        auth: |
            [network_identity]
            network_name = "{easytier-network-name}"
            network_secret = "{easytier-network-secret}"
storage:
    minio:
        root-credentials: |
            MINIO_ROOT_USER={minio_root_user}
            MINIO_ROOT_PASSWORD={minio_root_pass}
users:
    soulwhisper:
        password: {hashed-password}

```
