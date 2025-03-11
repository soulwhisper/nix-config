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
    lobechat:
        auth: |
            S3_ENDPOINT={cf-r2-endpoint}
            S3_PUBLIC_DOMAIN={cf-bucket-public-domain}
            S3_ACCESS_KEY_ID={cf-bucket-access-key}
            S3_SECRET_ACCESS_KEY={cf-bucket-secret-key}
            AUTH_GITHUB_ID={github-app-client-id}
            AUTH_GITHUB_SECRET={github-app-client-secret}
            DEEPSEEK_API_KEY={deepseek-api-token}
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
    dae:
        subscription: |
            {sub-url-1}
            {sub-url-2}
    easytier:
        auth: |
            [network_identity]
            network_name = "{easytier-network-name}"
            network_secret = "{easytier-network-secret}"
    tailscale:
        auth: {tskey-xxxx}
storage:
    minio:
        root-credentials: |
            MINIO_ROOT_USER={minio_root_user}
            MINIO_ROOT_PASSWORD={minio_root_pass}
users:
    soulwhisper:
        password: {hashed-password}

```
