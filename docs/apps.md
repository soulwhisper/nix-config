# Apps

- all pip3 packages is now rendered with "pkgs.unstable.uv".

## Easytier

- servers use systemd and config file, clients use gui.
- OPNSense: firewall/nat/port-forward, Interface=WAN, Protocol=TCP/UDP, Dest=WAN net, Port=11010, Redirect={Server}, Port=11010; clients use `-p tcp://{domain}:11010`;
- alternatives: tailscale(>2000ms).

## Netbox

- add group `netbox` to caddy-user, disable `ProtectHome` from caddy;
- run `netbox-manage migrate` after plugins enable / disable, netbox upgrade;
- run `netbox-manage createsuperuser` to create superuser;

## Systemd

- avoid the start limit;
- if service fails to start more than 5 times within a 10 seconds interval, systemd gives up restarting your service. Forever.
- set `StartLimitIntervalSec=0` under `unitConfig`;

## Chinese Input

- [rime-shuangpin-fuzhuma](https://github.com/gaboolic/rime-shuangpin-fuzhuma), primary;
- based on `linux:fcitx5-rime, macos:squirrel-app`;

## Ports

```shell
# should-not-change
caddy: 80,443
sftpd: 2022
http-proxy: 1080
garage: 3900
AMT-server: 4433
postgres: 5432
n8n: 5678
versitygw: 7070
home-assistant: 8123
prometheus: 9090
unifi: 8080,8443,8880,8843,6789,3478,10001
wireguard: 51820
avahi: 60000-65000

# remap
## dns-stack
adguard: 53
bind9: 5300
powerdns: 5301

## storage, 9000-9099
minio: 9000,9001
zot: 9002
forgejo: 9003,9004

## monitor, 9100-9199, internal
node-exporter: 9101
zfs-exporter: 9102
nut-exporter: 9103
smartctl-exporter: 9104
zrepl-exporter: 9105

## system, 9200-9299
adguard-ui: 9200
mihomo-ui: 9201
sftpgo-ui: 9202
meshcentral: 9203

## k8s, 9300-9399
talos-api: 9300
talos-pxe: 9301

## llm, 9400-9499
ollama: 9400

## app-dev, 9500-9799
postgrest: 9500

## app, 9800-9999
ocis: 9800
netbox: 9801
karakeep: 9802
immich: 9803
moviepilot: 9804,9805
emby: 9806
qbittorrent: 9807,65000
crafty: 9808,25500-25600

```
