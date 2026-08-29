# Runbook

Copy-paste procedures for deploy, troubleshooting, and maintenance.

## soulwhisper-studio (headless Mac Studio)

One-time provisioning (through the JetKVM console):

```shell
# 1. Remote Login (SSH); keys already installed by users.nix
sudo systemsetup -setremotelogin on
# then disable password auth in /etc/ssh/sshd_config: PasswordAuthentication no

# 2. FileVault ON (protects ssh keys, API tokens, KB corpus at rest).
#    Auto-login stays OFF — omlx runs as a launchd daemon, no session needed.
sudo fdesetup enable
# planned reboots skip the pre-boot password prompt:
sudo fdesetup authrestart

# 3. Time Machine: exclude re-downloadable model weights (~45GB)
tmutil add-exclusion ~/.omlx/models
# + quota the TM share on the Synology side (TM grows to fill)

# 4. Spotlight: do not index model weights
sudo mdutil -i off -d ~/.omlx/models 2>/dev/null || true
# (System Settings → Siri & Spotlight → Spotlight Privacy → add ~/.omlx/models)

# 5. Do NOT `brew services start omlx` — org.nixos.omlx launchd daemon owns it.
```

UPS failover (Synology NUT server side, then verify):

- Configure the NUT server to cut outlet power after client halt
  (`offdelay` / `shutdown.return`): without it, a UPS-triggered graceful
  shutdown leaves the Mac off — `autorestart 1` only fires on power loss
  while running.
- Verify with a live pull-plug test: mains out → Mac shuts down cleanly →
  UPS drops load → mains back → Mac boots, `omlx serve` reachable on :8000.

Hard hang recovery: smart plug (Shelly, on the UPS feed, power-on state=ON)
between UPS outlet and Mac Studio → toggle via Home Assistant. JetKVM
cannot power-cycle a Mac.

Unrecoverable remotely: recoveryOS (physical power-button hold) and DFU
(needs a second Mac + Apple Configurator 2). Updates are attended events
(`softwareupdate --schedule off` is set by the config).

## Deploy-time proxy

### macOS (after deploy, if needed)

Append to `/Users/soulwhisper/.config/fish/conf.d/set_proxy.fish`:

```fish
export "http_proxy=http://127.0.0.1:1080"
export "https_proxy=http://127.0.0.1:1080"
export "no_proxy=.homelab.internal,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
```

### NixOS (before first deploy, if needed)

Add to the host configuration:

```nix
networking.proxy.default = "http://ip:port";
networking.proxy.noProxy = "127.0.0.1,localhost,.homelab.internal";
```

## Systemd troubleshooting

```shell
# list failed units
systemctl list-units | grep failed

# debug and finish unfinished tmpfiles rules
sudo SYSTEMD_LOG_LEVEL=debug systemd-tmpfiles --create
```

Start-limit trap: if a service fails more than 5 times within 10 seconds,
systemd stops restarting it permanently. Prevent with:

```nix
unitConfig.StartLimitIntervalSec = 0;
```

## Sudo wrapper

When `sudo` fails with `must be owned by uid 0 and have the setuid bit set`,
invoke the wrapper directly:

```shell
/run/wrappers/bin/sudo <cmd>
```

## Git recipes

```shell
# squash the last 3 commits into one, keeping all messages for editing
git reset --soft HEAD~3 && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
git push --force-with-lease
```

## Shell defaults

- NixOS: `bash` is the login shell; run `fish` after SSH.
- macOS: `fish` is default.

## Development environment

```shell
# bootstrap: mise up, rtk init, omp seed
just bootstrap
```
