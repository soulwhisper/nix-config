# Priavte nix-cache

- status: deprecated, use mirror and tproxy instead

## requirements

- nix-nas with dae and minio
- other nixos push pkgs to nix-nas, use nix-nas as substituter

## configs

- `hosts/_modules/common/nix.nix`

```shell
"{ config, inputs, lib, ... }:{}"

nix.settings.trusted-substituters = [ "https://s3.noirpime.com/nix-cache" ]
nix.settings.trusted-public-keys = [ "s3.noirprime.com:5PWoDM0a9ahBdLRaEP6QxTe0UP0T9mVQJYYI6tQK36U=" ]

# After build push pkgs to private cache
nix.settings.post-build-hook = if config.modules.services.nix-cache.enable then
                        "/etc/nix-cache/upload-cache.sh"
                      else
                        "";
nix.settings.secret-key-files = if config.modules.services.nix-cache.enable then
                        "/etc/nix-cache/nix-cache-key.private"
                      else
                        "";
```

- `~/.aws/credentials`

```shell
[nix-cache]
aws_access_key_id=nix-cache
aws_secret_access_key=<nix-cache-key>
```

- allow anyone download from bucket "nix-cache"

```shell
mc anonymous set download nix-cache
```

- set policy for bucket "nix-cache"

```shell
{
            "Version": "",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": ["s3:*"],
                    "Resource": [
                        f"arn:aws:s3:::nix-cache",
                        f"arn:aws:s3:::nix-cache/*"
                    ]
                }
            ]
        }
```
