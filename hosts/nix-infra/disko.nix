# This file is the general template for xfs disk config.
{...}: let
  xfsMountOptions = [
    "defaults"
    "noatime"
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
