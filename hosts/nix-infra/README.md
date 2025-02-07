# NIX-INFRA

NIX-INFRA is a NixOS configuration for managing a NAS (Network Attached Storage) server with a hybrid setup. The system uses the NixOS declarative configuration model to manage the root filesystem, while application data and shared storage are not handled by an imported ZFS pool.

Check NIX-NAS for ZFS version.

## Main Differences

- enable firewall
- remove nfs and samba to shrink disk size
- remove unused apps: smartd, nut, kms, zotregistry, restic
