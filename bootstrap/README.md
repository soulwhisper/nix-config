## Bootstrap NixOS

- 1, disko-install with a minimal config, since iso nix-store using 8GB tmpfs;
- 2, switch to target host;

```shell
# : boot with nixos-minimal, latest kernel
passwd
sudo ifconfig ens192 down
sudo ifconfig ens192 172.19.82.10 netmask 255.255.255.0
sudo ifconfig ens192 up
sudo ip route del default
sudo ip route add default via 172.19.82.1
sudo nano /etc/resolv.conf
  nameserver 172.19.80.172

# :: opt, ssh in

# : init using bootstrap config, assume target host is 'nix-ops';
export https_proxy=http://ip:port

git clone https://github.com/soulwhisper/nix-config /tmp/nix-config
nixos-generate-config --no-filesystems --root /tmp/config
cp /tmp/config/etc/nixos/hardware-configuration.nix /tmp/nix-config/bootstrap/
cp /tmp/nix-config/hosts/nix-ops/disko.nix /tmp/nix-config/bootstrap/

# :: comment './zfs-support.nix' if not needed
vim /tmp/nix-config/bootstrap/configuration.nix

# :: install
sudo nix --extra-experimental-features 'nix-command flakes' run 'github:nix-community/disko/latest#disko-install' -- --mode mount --write-efi-boot-entries --flake '/tmp/nix-config/bootstrap#nixos' --disk main /dev/sda

# :: check then reboot
zfs list
reboot

# : login as user
mkdir -p /home/soulwhisper/.config/age
nano /home/soulwhisper/.config/age/keys.txt

# : deploy host
git clone https://github.com/soulwhisper/nix-config /home/soulwhisper/nix-config
sudo cp /etc/nixos/hardware-configuration.nix nix-config/hosts/nix-ops/hardware-configuration.nix
sudo nixos-rebuild switch --flake nix-config/.#nix-ops

# if goproxy fails
sudo systemctl edit --runtime nix-daemon.service
[Service]
Environment="GOPROXY=https://goproxy.cn,direct"
sudo systemctl restart nix-daemon.service

```
