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
- hass is installed as [supervised](https://github.com/home-assistant/supervised-installer) with dae, restic and other containers. In a debian vm.
- which also means nix pkg "home-assistant" and relevant apps are removed from my nixos configs.
- check "scripts/hass-supervised" for related scripts and compose yaml files.
- good examples, [ref1](https://github.com/scstraus/home-assistant-config);

## Easytier

- check "easytier.md"