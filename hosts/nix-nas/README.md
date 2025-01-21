# NIX-NAS

NIX-NAS is a NixOS configuration for managing a NAS (Network Attached Storage) server with a hybrid setup. The system uses the NixOS declarative configuration model to manage the root filesystem, while application data and shared storage are handled by an imported ZFS pool.

## Features

### 1. **Root Filesystem Management**

- Leverages NixOS to manage the root filesystem for:
  - System configurations.
  - Application deployments.
  - User management.
- Root filesystem remains independent of the ZFS pool for simplicity and robustness.

### 2. **ZFS for Data Storage**

- Application data is stored in an imported ZFS pool.
- Benefits of ZFS include:
  - Advanced snapshot and rollback capabilities.
  - Compression and deduplication for optimized storage use.
  - Fault tolerance and data integrity through checksumming.

### 3. **Applications**

The configuration includes multiple essential services:

- **Core Infrastructure**:

  - **DNS**: Manage local network DNS.
  - **NTP**: Provide accurate time synchronization.
  - **Reverse Proxy**: Handle HTTPS and routing for hosted services.

- **Storage Services**:

  - **SMB**: Windows-compatible file sharing.
  - **NFS**: Network filesystem for Unix-like clients.
  - **S3-Compatible Object Storage**: Enable object storage interfaces for compatible applications.

## ZFS Pool Creation

- ZFS disks = 2 / 4, use 2-Way Mirror;
- ZFS disks >= 5, use RAID-Z2, with extra slog and metadata.

```shell
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

zfs create numina/apps
zfs create numina/backup
zfs create numina/media
zfs create numina/timemachine

zfs create numina/replication -o compression=zstd -o mountpoint=none -o canmount=off

chown 0:0 /numina
chown -R 1001:1001 /numina/apps

```
