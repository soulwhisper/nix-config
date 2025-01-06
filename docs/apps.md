# Apps

- below apps have pre-defined configs, will have additonal files in /etc/appname.
    - dae
    - gatus
    - glance

- below apps need persistant data, will run as 1001:1001 with custom dataDir.
    - homebox
    - minio
    - unifi-controller

## Home-assistant

- due to nix support for custom components,
- haas is installed as [supervised](https://github.com/home-assistant/supervised-installer) with dae, restic and other containers. In a debian vm.
- which also means nix pkg "home-assistant" and relevant apps are removed from my nixos configs.
- check "scripts/haas-supervised" for related scripts and compose yaml files.

## Easytier

- check "easytier.md"