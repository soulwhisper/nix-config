# SOPS

## Encrypt / Decrypt

```shell
export SOPS_AGE_KEY_FILE=keys.txt

sops --verbose -i -d secrets.sops.yaml
sops --verbose -i -e secrets.sops.yaml
```

## Template

- all values should not have quotes;

```shell
networking:
    cloudflare:
        auth: {cf-api-token}
    dae:
        subscription: |
            {sub-url-1}
            {sub-url-2}
storage:
    minio:
        root-credentials: |
            MINIO_ROOT_USER={minio_root_user}
            MINIO_ROOT_PASSWORD={minio_root_pass}

users:
    soulwhisper:
        password: {hashed-password}

```