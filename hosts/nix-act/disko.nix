# This file is the general template for 'lvm-thin-xfs,tmpfs-root' disk config.
# Main disk should be at least 500 GB for the default LV sizes.
{ ... }:
let
  xfsMountOptions = [
    "defaults"
    "noatime"
    "pquota"
  ];
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # N100: confirm the target with `lsblk` (nvme0n1 vs sda).
        # when using disko-install, device value will be overwritten
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            primary = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "main";
              };
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=10G"
        "defaults"
        "mode=755"
      ];
    };
    lvm_vg = {
      main = {
        type = "lvm_vg";
        lvs = {
          thinpool = {
            # Do not hardcode a size larger than the target PV. 90% leaves
            # room for LVM metadata and later lvextend on a 1TB disk.
            size = "90%";
            lvm_type = "thin-pool";
          };
          app = {
            size = "250G";
            lvm_type = "thinlv";
            pool = "thinpool";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/var/lib";
              mountOptions = xfsMountOptions ++ [ "logbsize=64k" ];
            };
          };
          home = {
            size = "100G";
            lvm_type = "thinlv";
            pool = "thinpool";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/home";
              mountOptions = xfsMountOptions;
            };
          };
          nix = {
            size = "150G";
            lvm_type = "thinlv";
            pool = "thinpool";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/nix";
              mountOptions = xfsMountOptions;
            };
          };
        };
      };
    };
  };
}
