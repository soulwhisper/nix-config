# Notes

- networking.cloudflare.auth => CF-API:ZONE:DNS:EDIT
- atuin-key should be base64 format
- change terminal theme to "catppuccin-mocha"
- change terminal font to "Jetbrains Nerd Font Mono Light"

## Deprecations

### Bind9 / Powerdns

- DNS features better than adguard, external-dns supports also great;
- Deprecated due to lack of management and UI support;
- opnsense plugin `os-bind` is not stable, [ref1](https://github.com/kubernetes-sigs/external-dns/issues/3721), [ref2](https://github.com/opnsense/plugins/pull/4177);

### Dae

- Deprecated due to the inability of builtin connectivity check performance;

### GoHarbor

- due to the complexity, goharbor could only be containers;
- the implementation follows bitnami compose, [link](https://github.com/bitnami/containers/blob/main/bitnami/harbor-portal/docker-compose.yml);
- official installer create nine services, with headless podman it needs 6 ports on localhost;
- however bitnami sunseted its compose configs, it is hard to follow both official environments and bitnami simplicities now;
- deprecated, use zotregistry instead;

### Minio

- Deprecated due to UI management removal and paid-gate;
- use Garage (General) or Versity Gateway (NAS) instead;

### Terminals

- `iTerm2` overshines with features and customizability; However, even in 2024, `iTerm2` still not support GPU rendering with ligatures enabled [ref](https://gitlab.com/gnachman/iterm2/-/issues/11382#note_1800562701);
- for this part, `Ghostty` breaks in;

### Vscode by nix-darwin

- deprecated since profile sync works better;

### Yabai & Skhd

- installed by nix-darwin, without proper uninstallation methods;
- will break system even after service disabled; appname=org.nixos.yabai/skhd;

## Useful commands

```shell
# import age keys
## darwin-before: /Users/<username>/Library/Application\ Support/sops/age/keys.txt
## darwin-after: /Users/<username>/.config/age/keys.txt

# darwin run below after deploy if necessary
export "http_proxy=http://127.0.0.1:1080" >> /Users/soulwhisper/.config/fish/conf.d/set_proxy.fish
export "https_proxy=http://127.0.0.1:1080" >> /Users/soulwhisper/.config/fish/conf.d/set_proxy.fish
export "no_proxy=.homelab.internal,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16" >> /Users/soulwhisper/.config/fish/conf.d/set_proxy.fish

# nixos add below to configuration.nix before deploy if necessary
networking.proxy.default = "http://ip:port";
networking.proxy.noProxy = "127.0.0.1,localhost,.homelab.internal";

## fix unfinished tmpfiles
systemd-tmpfiles --tldr | grep apps
SYSTEMD_LOG_LEVEL=debug systemd-tmpfiles --create

## list failed systemd units
systemctl list-units | grep failed

## squash multi comments
git reset --soft HEAD~3 && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
git push --force-with-lease

```
