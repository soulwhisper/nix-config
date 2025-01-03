# NIX-VPN

NIX-VPN is a NixOS configuration for managing a VPN server with a hybrid setup. The system uses the NixOS declarative configuration model to manage the root filesystem.

## APPS

- chrony
- ddns
- easytier-server
- headscale

## Post-Deployment

- add "lab.noirprime.com" at ddns, "localhost:9201";
- add port 51900/tcp to router-firewall;