# This file is the general template for lvm-thin-xfs and tmpfs-root disk config.
{...}: let
  xfsMountOptions = [
    "defaults"
    "noatime"
    "ikeep" # become defaults after 2025.09
    "pquota"
  ];
in {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
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
                mountOptions = ["umask=0077"];
              };
            };
            primary = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "mainpool";
              };
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=4G"
        "defaults"
        "mode=755"
      ];
    };
    lvm_vg = {
      mainpool = {
        type = "lvm_vg";
        lvs = {
          thinpool = {
            size = "20G";
            lvm_type = "thin-pool";
          };
          app = {
            size = "10M";
            lvm_type = "thinlv";
            pool = "thinpool";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/var/lib";
              mountOptions = xfsMountOptions ++ ["logbsize=64k"];
            };
          };
          home = {
            size = "10M";
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
            size = "10M";
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
