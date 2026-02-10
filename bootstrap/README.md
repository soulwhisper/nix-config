## Bootstrap NixOS

- disko-install has issues; iso nix-store using 8GB tmpfs;
- 1, disko format with assuming host `disko.nix`;
- 2, nix-install with minimal bootstrap config;
- 3, switch to target host;

```shell
# : boot with nixos-minimal
sudo -s
passwd
ifconfig ens192 down
ifconfig ens192 172.19.82.10 netmask 255.255.255.0
ifconfig ens192 up
ip route del default
ip route add default via 172.19.82.1
echo "nameserver 172.19.80.172" >> /etc/resolv.conf

# :: opt, ssh in as root

# : init using bootstrap config, assuming target host is 'nix-ops';
export https_proxy=http://ip:port

git clone https://github.com/soulwhisper/nix-config /etc/nix-config
nixos-generate-config --no-filesystems
cp /etc/nixos/hardware-configuration.nix /etc/nix-config/bootstrap/
# cp /etc/nix-config/hosts/nix-ops/disko.nix /etc/nix-config/bootstrap/

cd /etc/nix-config
git add .

# :: uncomment './zfs-support.nix' if needed
vim /etc/nix-config/bootstrap/configuration.nix

# : install
nix --extra-experimental-features 'nix-command flakes' run 'github:nix-community/disko/latest' -- --mode destroy,format,mount "/etc/nix-config/bootstrap/disko.nix" --yes-wipe-all-disks

sudo nixos-install --flake "/etc/nix-config/bootstrap/.#nixos" --no-root-password

# : check then reboot
lsblk -fs
zfs list
reboot

# : login as user
mkdir -p /home/soulwhisper/.config/age
nano /home/soulwhisper/.config/age/keys.txt

# : deploy host
export https_proxy=
export GOPROXY=https://goproxy.cn,direct

git clone https://github.com/soulwhisper/nix-config /home/soulwhisper/nix-config
sudo nixos-generate-config --no-filesystems
sudo cp /etc/nixos/hardware-configuration.nix nix-config/hosts/nix-ops/
sudo -E nixos-rebuild switch --flake nix-config/.#nix-ops

# :: nix-ops, disk space too small
sudo mount -o remount,size=30G /
# :: nix-ops, expand lv
sudo lvresize -L +10G main/nix
sudo xfs_growfs /nix
```
