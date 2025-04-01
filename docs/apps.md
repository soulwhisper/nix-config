# Apps

- all pip3 packages is now rendered with "pkgs.unstable.uv".

## Easytier

- servers use systemd and config file, clients use gui.
- OPNSense: firewall/nat/port-forward, Interface=WAN, Protocol=TCP/UDP, Dest=WAN net, Port=11010, Redirect={Server}, Port=11010; clients use `-p tcp://{domain}:11010`;
- alternatives: tailscale(>2000ms).

## Home-assistant

- main program use nixos version, integrations using podman containers for compatibliaty;
- integrations using mDNS/avahi have random ports >32768;
- during tests, ui-lovelace use storage mode;
- homebridge dont have random high ports, so cant use with hass-stack;

## K8S-related

- service:adguard is not deprecated until opnsense plugin `os-bind` is stable, [ref1](https://github.com/kubernetes-sigs/external-dns/issues/3721), [ref2](https://github.com/opnsense/plugins/pull/4177);
- service:minio and service:nfs4 for k8s offsite backups, i.e. volsync;
- service:samba for macos backups;

## Netbox

- add group `netbox` to caddy-user, disable `ProtectHome` from caddy;
- run `netbox-manage migrate` after plugins enable / disable, netbox upgrade;
- run `netbox-manage createsuperuser` to create superuser;
- todo: move into k8s-cluster;

## Goharbor

- due to the complexity, goharbor remains containers
- to update goharbor version, run command below
- this service also follows bitnami compose, [link](https://github.com/bitnami/containers/blob/main/bitnami/harbor-portal/docker-compose.yml);

```shell
## full command
docker run --rm --privileged \
    -v ${dataDir}/harbor.yml:/input/harbor.yml \
    -v ${dataDir}/data:/data \
    -v ${dataDir}/compose:/compose_location \
    -v ${dataDir}/config:/config \
    -v /:/hostfs/ \
    goharbor/prepare:${harbor-version} prepare --with-trivy
## only update docker-compose.yml
docker run --rm --privileged \
    -v ${dataDir}/harbor.yml:/input/harbor.yml \
    -v ${dataDir}/compose:/compose_location \
    goharbor/prepare:${harbor-version} prepare --with-trivy
```

## Systemd

- avoid the start limit, set `StartLimitIntervalSec=0` under `unitConfig`;

## Ports

```shell
# should-not-change
adguard-dns: 53
caddy: 80,443
http-proxy: 1080
home-assistant: 8123
prometheus: 9090
unifi: 8080,8443,8880,8843,6789,3478,10001
matterircd: 6667

# remap
## storage, 9000-9099
minio: 9000,9001
zot: 9002
forgejo: 9003,9004

## monitor, 9100-9199, internal
node-exporter: 9100
zfs-exporter: 9101
nut-exporter: 9102
smartctl-exporter: 9103
zrepl-mon: 9104
netbird-mon: 9105,9106

## system, 9200-9299
adguard-ui: 9200
mihomo-ui: 9201
woodpecker: 9210,9211

## k8s, 9300-9399
talos-api: 9300
talos-pxe: 9301

## llm, 9400-9499
ollama: 9400

## app, 9800-9999
keycloak: 9800
mattermost: 9801
netbird: 9802,9803
netbox: 9804

# vpn
wireguard: 51820

```
