# Notes

- networking.cloudflare.auth => CF-API:ZONE:DNS:EDIT
- atuin-key should be base64 format
- change iterm2 theme to dark
- change iterm2 font to "firacode-nerd-font" afterwards
- caddy-custom, [ref](https://github.com/Ramblurr/nixos-caddy);
- tailscale for k8s nodes, easytier for everything else; when gitops stable, tailscale can be removed;

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

# DEBUG
## use latest golang
nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz -p go

## fix unfinished tmpfiles
systemd-tmpfiles --tldr | grep apps
SYSTEMD_LOG_LEVEL=debug systemd-tmpfiles --create

## list failed systemd units
systemctl list-units | grep failed

## squash multi comments
git reset --soft HEAD~3 && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
git push --force-with-lease

```
