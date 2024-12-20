# nix-config

[![built with nix](https://img.shields.io/badge/built_with_nix-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)

This repository holds my NixOS configuration. It is fully reproducible and flakes based.

- soulwhisper-mba, my macbook configs.
- nix-dev, devops vm for corp-env.
- nix-nas, nas vm for corp-env. Was TrueNAS Scale 24.10+.
- renovate configs and ci, managed by [soulwhisper/renovate-config](https://github.com/soulwhisper/renovate-config).

## About NAS

- NUC / VM, ZFS disks = 2 / 4, use 2-Way Mirror, nix-nas;
- Server, ZFS disks >= 5, use RAID-Z2, with extra slog and metadata, TrueNAS Scale 24.10+.
- Cluster, Mayastor / Ceph.

```shell
# zfs pool creation for nix-nas, un-encrypted, 2-way mirror
ls -l /dev/disk/by-id/
zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -O compression=on \
    -O relatime=on \
    -O xattr=sa \
    -O acltype=posixacl \
    numina \
    mirror \
    {disk-by-id-1} \
    {disk-by-id-2} \
    mirror \
    {disk-by-id-3} \
    {disk-by-id-4}

zfs create numina/backup
zfs create numina/media
zfs create numina/docs
zfs create numina/apps
zfs create numina/timemachine

```

## Usage

```shell
# darwin
## opt. run set-proxy script first
sudo python3 scripts/darwin_set_proxy.py
## build & diff
task nix:darwin-build HOST=soulwhisper-mba
## deploy
task nix:darwin-deploy HOST=soulwhisper-mba
## opt. set default proxy after configs imported
cp scripts/set_proxy.fish ~/.config/fish/conf.d/

# nixos, e.g. nix-nas
## set DNS record then test ssh connections
## cp machineconfig
cp /etc/nixos/hardware-configuration.nix hosts/nix-nas/hardware-configuration.nix
## build & diff
task nix:nixos-build HOST=nix-nas
## deploy
task nix:nixos-deploy HOST=nix-nas
```

## Inspiration

I got help from some cool configs like:

- [bjw-s/nix-config](https://github.com/bjw-s/nix-config)
- [Ramblurr/nixcfg](https://github.com/Ramblurr/nixcfg)