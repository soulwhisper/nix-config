# This file is the general template for xfs disk config.
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
            swap = {
              size = "16G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            primary = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/";
                mountOptions = xfsMountOptions;
              };
            };
          };
        };
      };
    };
  };
}
