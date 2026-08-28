# Services

Operational notes per service, followed by the port registry.
Module sources live in `hosts/_modules/nixos/services/`.

## General

- All `pip3`-installed Python tooling is replaced by `pkgs.unstable.uv`.

## EasyTier

- Servers run via systemd with a sops-provided config file; clients use the GUI.
- Client connect string: `-p tcp://{domain}:11010`.
- OPNsense port forward: Firewall → NAT → Port Forward, Interface = WAN,
  Protocol = TCP/UDP, Destination = WAN net, Port = 11010,
  Redirect target = {Server}, Redirect port = 11010.
- Chosen over Tailscale for latency (Tailscale relay exceeded 2000 ms in tests).

## Netbox

- Add group `netbox` to the caddy user and disable `ProtectHome` in caddy.
- Run `netbox-manage migrate` after enabling/disabling plugins and after upgrades.
- Create the admin account with `netbox-manage createsuperuser`.

## Proxy stacks

- `mosdns + sing-box`: best general-purpose stack, especially SOCKS5.
- `mihomo`: best for Kubernetes image pulling; SOCKS5 underperforms there.
- `dae`: unstable, breaks connections — rejected.

## Port registry

Fixed allocations should not change; ranges group services by function.

### Fixed

| Port | Service |
|---|---|
| 80, 443 | caddy |
| 53 | adguard |
| 514 | vector |
| 2022 | sftpgo (SSH) |
| 1080 | http proxy |
| 8000 | omlx (soulwhisper-studio) |
| 4433 | AMT server |
| 5432 | postgres |
| 5678 | n8n |
| 8123 | home-assistant |
| 9090 | prometheus |
| 11010 | easytier |
| 30000 | fvtt |
| 51820 | wireguard |
| 60000–65000 | avahi |

### DNS stack

| Port | Service |
|---|---|
| 53 | adguard |
| 5300 | mosdns |

### Storage (9000–9099)

| Port | Service |
|---|---|
| 9000, 9001 | minio / garage / versitygw |
| 9003, 9004 | forgejo |

### Exporters (9100–9199)

| Port | Service |
|---|---|
| 9100 | prometheus (node) |
| 9101 | node-exporter |
| 9102 | zfs-exporter |
| 9103 | nut-exporter |
| 9104 | smartctl-exporter |
| 9105 | zrepl-exporter |

### System UIs (9200–9299)

| Port | Service |
|---|---|
| 9200 | adguard-ui |
| 9201 | proxy-ui |
| 9202 | sftpgo-ui |
| 9203 | meshcentral |
| 9204 | scrutiny-ui |
| 9205 | stork-ui |

### Kubernetes infrastructure (9300–9499)

| Port | Service |
|---|---|
| 9300 | talos-api |
| 9400 | gatus |

### Application development (9700–9799)

| Port | Service |
|---|---|
| 9700 | postgrest |

### Applications (9800–9999)

| Port | Service |
|---|---|
| 9800 | dockge |
| 9801 | unifi-server |
| 9802 | netbox |
