## Bootstrap NixOS

```shell
## install nixos with iso and disko
nixos-generate-config --no-filesystems --root /tmp/config

export https_proxy=

git clone -b main https://github.com/soulwhisper/nix-config /tmp/nix-config

cp /tmp/config/etc/nixos/hardware-configuration.nix /tmp/nix-config/bootstrap/

nix --extra-experimental-features 'nix-command flakes' run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '/tmp/nix-config/bootstrap#nixos' --disk main /dev/sda

zfs list

reboot

## login as user
mkdir -p /home/soulwhisper/.config/age
nano /home/soulwhisper/.config/age/keys.txt

## deploy host
git clone -b main https://github.com/soulwhisper/nix-config /home/soulwhisper/nix-config
sudo cp /etc/nixos/hardware-configuration.nix nix-config/hosts/nix-nas/hardware-configuration.nix
sudo nixos-rebuild build --flake nix-config/.#nix-nas --show-trace --print-build-logs
sudo nixos-rebuild switch --flake nix-config/.#nix-nas

## if goproxy fails
sudo systemctl edit --runtime nix-daemon.service
[Service]
Environment="GOPROXY=https://goproxy.cn,direct"
sudo systemctl restart nix-daemon.service

```
