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
            size = "40G";
            lvm_type = "thin-pool";
          };
          app = {
            size = "10G";
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
            size = "5G";
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
            size = "20G";
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
