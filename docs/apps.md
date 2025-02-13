# Apps

- these apps { dae, glance, talos-pxe, nut } have pre-defined configs files in /etc/appname.
- by default, all apps will run as 1001:1001 with dataDir "/opt/apps/appname".
- system apps might still use root / specific-users.
- all pip3 packages is now rendered with "pkgs.unstable.uv".

## K8S

- service:adguard is not deprecated until opnsense plugin `os-bind` is stable, [ref1](https://github.com/kubernetes-sigs/external-dns/issues/3721), [ref2](https://github.com/opnsense/plugins/pull/4177);
- service:minio for k8s offsite backups, i.e. volsync;
- service:nfs and service:restic is disabled;
- service:samba for windows / macos backups;

## Exceptions

### Easytier

- servers use userspace-networking(no-tun), clients use gui.
- with systemd-service, dont need config.toml anymore;
- homebrew cask easytier-gui is broken, download easytier-cli from github manually.
- OPNSense: firewall/nat/port-forward, Interface=WAN, Protocol=TCP/UDP, Dest=WAN net, Port=11010, Redirect={Server}, Port=11010; client use `-p tcp://{domain}:11010`;
- alternatives: tailscale(>=2000ms).

### Irrelevant dataDir

- adguard, due to external-dns update method, mutableSettings=true is enough;
- chrony / kms / talos-api, temp working files;
- dae / talos-pxe, pre-defined configs;
- easytier / glance / nut, declarative configs;

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
mqtt-ui: 9202
syncthing-ui: 9203

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
