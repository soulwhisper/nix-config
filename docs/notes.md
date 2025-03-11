# Notes

- networking.cloudflare.auth => CF-API:ZONE:DNS:EDIT
- atuin-key should be base64 format
- change terminal theme to "catppuccin-mocha"
- change terminal font to "MonaspiceKr Nerd Font Mono", size=12, thicken=true
- auto rebuild nixos by service "auto-rebuild";

## Bug tracker

- dae, domain timeout; solution issue, [ref](https://github.com/daeuniverse/dae/issues/776#issuecomment-2709345478);

## Useful commands

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

## local rebuild
nixos-rebuild build --flake nix-config/.#nix-nas --show-trace
nvd diff /run/current-system result

## wipe s3 bucket
nix-shell -p awscli
aws configure
aws --endpoint-url=https://<account_id>.r2.cloudflarestorage.com s3 ls s3://<bucket_name>/ --recursive
aws --endpoint-url=https://<account_id>.r2.cloudflarestorage.com s3 rm s3://<bucket_name>/ --recursive

## fix unfinished tmpfiles
systemd-tmpfiles --tldr | grep apps
SYSTEMD_LOG_LEVEL=debug systemd-tmpfiles --create

## list failed systemd units
systemctl list-units | grep failed

## squash multi comments
git reset --soft HEAD~3 && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
git push --force-with-lease

## remove unknown services
rm -f /run/systemd/transient/*.timer
rm -f /run/systemd/transient/*.service

```
