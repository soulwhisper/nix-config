# NIX-NAS

**NIX-NAS** is a declarative NixOS configuration for enterprise-grade Network Attached Storage solutions. This implementation combines NixOS's immutable infrastructure paradigm with ZFS's enterprise storage capabilities, using a hybrid approach where the OS root is managed by NixOS while storage operations are handled through a dedicated ZFS pool.

## Features

### 1. **Declarative Infrastructure with NixOS**

- **Immutable Root FS**: Managed entirely through Nix Flakes;
- **ZFS Impermanence**: Unlike traditional FHS, nixos can boot with only "/boot" and "/nix";
  - Static data in "/nix", State data in "/persist";
  - every boot in a clean state, powered by zfs snapshot;

### 2. **ZFS for Root Storage**

- Nixos on ZFS, powered by disko.
- Benefits of ZFS include:
  - Advanced snapshot and rollback capabilities.
  - Compression and deduplication for optimized storage use.
  - Fault tolerance and data integrity through checksumming.
- Expand priority: add 1 disk for root mirror; add more mirror pool.

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
