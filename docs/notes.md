# Notes

- networking.cloudflare.auth => CF-API:ZONE:DNS:EDIT
- atuin-key should be base64 format
- change terminal theme to "catppuccin-mocha"
- change terminal font to "Jetbrains Nerd Font Mono Light"
- all nixos system migrate from linux-on-legacy to linux-on-zfs;
- zfs-impermanence template is "hosts/\_modules/nixos/filesystems/zfs/disk-config.nix";
- since git-operations using vscode and workspace, remove gnupg and git-auth from configs;

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
