# Decisions

Why components were rejected or deprecated. Each entry records the trigger and
the outcome so the same dead end is not revisited.

## Bind9 / PowerDNS — rejected

- DNS features outclass adguard and external-dns support is strong.
- Rejected for lack of management/UI; OPNsense plugin `os-bind` is unstable.
- References: [external-dns#3721](https://github.com/kubernetes-sigs/external-dns/issues/3721),
  [opnsense/plugins#4177](https://github.com/opnsense/plugins/pull/4177).

## Dae — deprecated

- Builtin connectivity checks underperform; connections break often.
- Replaced by mosdns + sing-box / mihomo (see [services.md](services.md)).

## GoHarbor — deprecated

- Only viable as containers due to complexity; official installer creates nine
  services (6 localhost ports with headless podman).
- The followed bitnami compose layout was sunset, making it unmaintainable.
- ~~Replaced by zotregistry~~ → zotregistry itself moved to a containerized
  deployment (single-process build could not sustain duplicate-request loads at
  10G+ bandwidth); its packages and service module were removed here (2026-08-25).

## Minio — deprecated

- UI management removed; features pay-gated.
- Replaced by Garage (general S3) or Versity Gateway (NAS).

## iTerm2 → Ghostty — replaced

- iTerm2 leads on features/customization but still lacks GPU rendering with
  ligatures enabled ([ref](https://gitlab.com/gnachman/iterm2/-/issues/11382#note_1800562701)).
- Ghostty covers this; adopted as the terminal emulator.

## VSCode via nix-darwin — deprecated

- Profile sync works better; managed installs dropped.

## Yabai & Skhd — rejected

- Installed by nix-darwin without a proper uninstall path (`org.nixos.yabai/skhd`);
  systems broke even after disabling the services. Not used again on macOS.
