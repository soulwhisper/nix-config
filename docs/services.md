# Services

Operational notes per service, followed by the port registry.
Module sources live in `hosts/_modules/nixos/services/`.

## General

- All `pip3`-installed Python tooling is replaced by `pkgs.unstable.uv`.

## Corporate PKI and Forgejo

- `nix-dev` runs the online intermediate CA, Caddy, Forgejo, and its private
  PostgreSQL 18 cluster. It is not the root authority or deployment controller.
- Production CA material must be supplied through SOPS before activating the
  enabled host configuration. No root, certificate, or password is generated
  automatically to replace missing material.
- Git URL: `https://git.internal.htkrail.com/`; PKI public artifacts:
  `https://pki.internal.htkrail.com/`.
- CA API: `https://localhost:9700/acme/acme/directory`, loopback only.
- Forgejo HTTP uses `127.0.0.1:9003`; Git SSH is disabled. Its PostgreSQL cluster
  uses `/run/postgresql-forgejo`, not the host's shared PostgreSQL instance.
- PKI, Forgejo, and its PG18 unit use the existing appuser (UID/GID1001), with local
  systemd units and native JSON/INI/config generators. Shared UID ownership is not
  isolation between applications. Database administration uses a root-only peer map.
- Controller fish functions use overlay packages `corp-root-ca` and
  `corp-deployment-tools`; `corp-forgejo` wraps the official server binary.
- See [the corporate services runbook](corporate-services.md) for provisioning,
  controller commands, rotation, backups, recovery, and activation requirements.

## Caddy

- All hosts retain `pkgs.caddy-custom`; disabling a provider does not change the
  binary or remove its compiled plugin.
- `modules.services.caddy.cloudflare.enable` defaults to `true`. When disabled,
  no Cloudflare DNS challenge, email variable, or environment file is configured.
- `nix-dev` disables Cloudflare and has no Cloudflare SOPS credential. Its PKI and
  Git sites use the private ACME issuer instead.
- When Cloudflare is enabled, `modules.services.caddy.authFile` is required.

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
| 9003 | forgejo HTTP (loopback only) |
| 9004 | forgejo SSH (reserved; disabled) |

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
| 9700 | pki / step-ca (loopback only) |

### Applications (9800–9999)

| Port | Service |
|---|---|
| 9800 | dockge |
| 9801 | unifi-server |
| 9802 | netbox |
