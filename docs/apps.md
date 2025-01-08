# Apps

- these apps { dae, glance, talos-pxe, nut } have pre-defined configs files in /etc/appname.
- by default, all apps will run as 1001:1001 with dataDir "/opt/apps/appname".
- system apps might still use root / specific-users.

## Exceptions

### Home-assistant

- due to nix support for custom components,
- hass is installed as [supervised](https://github.com/home-assistant/supervised-installer) with dae, restic and other containers. In a debian vm.
- which also means "home-assistant" and relevant apps are fully removed from my nix-configs.
- check "scripts/hass-supervised" for related scripts and compose files.
- good examples, [ref1](https://github.com/scstraus/home-assistant-config);

### Easytier

- check "easytier.md"

## Ports

```shell
# unchangeable
adguard-dns: 53
unifi: 8080,8443,8880,8843,6789,3478,10001

# should-not-change
caddy: 80,443
dae-http: 1080
easytier-socks5: 1081
home-assistant: 8123
prometheus: 9090

# remap
## storage, 9000-9099
minio: 9000,9001
zot: 9002
zrepl: 9003

## monitor, 9100-9199, internal
node-exporter: 9100
nut-exporter: 9101
smartctl-exporter: 9102
zrepl-metrics: 9103

## system, 9200-9299
adguard-ui: 9200
ddns-ui: 9201
syncthing-ui: 9202

## k8s, 9300-9399
talos-api: 9300
talos-pxe: 9301

## app, 9800-9999
gatus: 9801
glance: 9802
homebox: 9803

# vpn
wireguard: 51820

```