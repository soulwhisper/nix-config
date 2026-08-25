# Runbook

Copy-paste procedures for deploy, troubleshooting, and maintenance.

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
