# Notes

- networking.cloudflare.auth => CF-API:ZONE:DNS:EDIT
- atuin-key should be base64 format
- change iterm2 theme to dark
- change iterm2 font to "firacode-nerd-font" afterwards
- caddy-custom, [ref](https://github.com/Ramblurr/nixos-caddy);

```shell
# install req. incl. cachix & nvd
curl -L https://nixos.org/nix/install | sh
nix-env -iA cachix -f https://cachix.org/api/v1/install
nix-env -iA nixpkgs.nvd

# import age keys
## darwin-before: /Users/<username>/Library/Application\ Support/sops/age/keys.txt
## darwin-after: /Users/<username>/.config/age/keys.txt

# darwin run below after deploy if necessary
export "http_proxy=http://127.0.0.1:7890" >> /Users/soulwhisper/.config/fish/conf.d/set_proxy.fish
export "https_proxy=http://127.0.0.1:7890" >> /Users/soulwhisper/.config/fish/conf.d/set_proxy.fish
export "no_proxy=.homelab.internal,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16" >> /Users/soulwhisper/.config/fish/conf.d/set_proxy.fish

# nixos add below to configuration.nix before deploy if necessary
networking.proxy.default = "http://ip:port";
networking.proxy.noProxy = "127.0.0.1,localhost,.homelab.internal";

# push with gpg signed
export GPG_TTY=$(tty)
gpg --import privatekey
gpt --import publickey
git config --global user.signingkey <gpg-id>
git config --global commit.gpgsign true
```

## service ports remap

```shell
# unchangeable
adguard-dns: 53
unifi: 8080,8443,8880,8843,6789,3478,10001

# should-not-change
caddy: 80,443
dae: 1080
home-assistant: 8123

# remap
## storage, 9000-9099
minio: 9000,9001
zrepl: 9002

## monitor, 9100-9199
node-exporter: 9100
smartctl-exporter: 9101
zrepl-metrics: 9102

## system, 9200-9299
adguard-ui: 9200
ddns-ui: 9201
syncthing-ui: 9202

## k8s, 9300-9399
talos-api: 9300
talos-pxe: 9301

## app, 9800-9999
gatus: 9801
glance: 9802
homebox: 9803

```

## TODO
- [ ] add more backup services to nix-nas, make it production ready;
    - zrepl, backup zfs to remote-sites;
    - borg, backup linux-servers to nas; and "borg compact";
    - rclone, backup clouds to nas;
    - syncthing, backup devices to nas;

- [x] add pxe services to nix-dev, support k8s bootstrap;
- [ ] rewrite nix-dev to VM template;
- [ ] add tailscale to all nix hosts;

- [ ] add a few more desktop services to nix-dev, and wayland, [ref](https://github.com/Ramblurr/nixcfg/blob/main/modules/default.nix);
