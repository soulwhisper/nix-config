# Apps

- all pip3 packages is now rendered with "pkgs.unstable.uv".

## Easytier

- servers use systemd and config file, clients use gui.
- OPNSense: firewall/nat/port-forward, Interface=WAN, Protocol=TCP/UDP, Dest=WAN net, Port=11010, Redirect={Server}, Port=11010; clients use `-p tcp://{domain}:11010`;
- alternatives: tailscale(>2000ms).

## Home-assistant

- main program use nixos version, integrations using podman containers for compatibliaty;
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

## Goharbor

- due to the complexity, goharbor could only be containers;
- the implementation follows bitnami compose, [link](https://github.com/bitnami/containers/blob/main/bitnami/harbor-portal/docker-compose.yml);
- official installer create nine services, with headless podman it needs 6 ports on localhost;
- however bitnami sunseted its compose configs, it is hard to follow both official environments and bitnami simplicities now;
- deprecated, use zotregistry instead;

```shell
## create/update config and compose files based on installer
docker run --rm --privileged \
    -v "$PWD/harbor.yml:/input/harbor.yml" \
    -v "$PWD/compose:/compose_location" \
    -v "$PWD/config:/config" \
    goharbor/prepare:v2.12.2 prepare --with-trivy
```

## Podman

- with `virtualisation.podman.defaultNetwork.settings.dns_enabled = true;`, default network could resolve containerName;
- no longer need to create custom networks, or using `host.containers.internal:{port}`, reduce complexity;
- req: bind local dns service to physical interface and `127.0.0.1`, instead of `0.0.0.0`;

```shell
# old days with `networking.firewall.interfaces."podman*".allowedUDPPorts = [53 5353];`
# related services use `extraOptions = [ "--network={networkName}" ];`;
# script could also be `podman network create {networkName} --ignore`;
# after script add `--internal` if network is internal;
  systemd.services.podman-create-network-{networkName} = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "{podman-containerName}.service" ];
    script = ''
      podman network exists {networkName} || podman network create {networkName}
    '';
  };
```

## Systemd

- avoid the start limit;
- if service fails to start more than 5 times within a 10 seconds interval, systemd gives up restarting your service. Forever.
- set `StartLimitIntervalSec=0` under `unitConfig`;

## Ports

```shell
# should-not-change
caddy: 80,443
http-proxy: 1080
AMT-server: 4433
postgres: 5432
n8n: 5678
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
node-exporter: 9100
zfs-exporter: 9101
nut-exporter: 9102
smartctl-exporter: 9103
zrepl-mon: 9104

## system, 9200-9299
adguard-ui: 9200
mihomo-ui: 9201
meshcentral: 9203

## k8s, 9300-9399
talos-api: 9300
talos-pxe: 9301

## llm, 9400-9499
ollama: 9400

## app-dev, 9500-9799
postgrest: 9500

## app, 9800-9999
netbox: 9801
karakeep: 9802
immich: 9803
moviepilot: 9804,9805
emby: 9806
qbittorrent: 9807,65000
crafty: 9808,25500-25600

```
