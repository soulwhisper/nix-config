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

- unchangeable services like unifi not touched;
- reverse proxy use 80 /443; dns & proxy ports not changed;
- only remap duplicated ports below;
- storage services use 9000 - 9099;
- monitor services use 9100 - 9199;
- web services use 9800 - 9999;

```shell
# unchangeable
adguard-dns: 53,67,68
unifi: 8080,8443,8880,8843,6789,3478,10001

# should-not-change
caddy: 80,443
dae: 1080
home-assistant: 8123
minio: 9000,9001
node-exporter: 9100

# remap
adguard-ui: 9800
gatus: 9801
glance: 9802
homebox: 9803
discovery-api: 9900

```