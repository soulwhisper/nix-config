# NIX-INFRA

NIX-INFRA is a NixOS configuration for managing a NAS (Network Attached Storage) server with a hybrid setup. The system uses the NixOS declarative configuration model to manage the root filesystem, while application data and shared storage are not handled by an imported ZFS pool.

Check NIX-NAS for ZFS version.

## Post-Deployment

- add "lab.noirprime.com" at ddns, "localhost:9201";
- add port 51900/tcp to router-firewall;