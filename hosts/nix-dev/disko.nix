# https://github.com/nix-community/disko-templates/blob/main/zfs-impermanence/disko-config.nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # when using disko-install, this value will be overwritten
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
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        rootFsOptions = {
          # https://wiki.archlinux.org/title/Install_Arch_Linux_on_ZFS
          acltype = "posixacl";
	      atime = "off";
	      compression = "zstd";
          mountpoint = "none";
          xattr = "sa";
        };
        options.ashift = "12";
        datasets = {
          "root" = {
	        type = "zfs_fs";
            mountpoint = "/";
            # Used by services.zfs.autoSnapshot options. Only apps dataset needs snapshot.
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^rpool/root@blank$' || zfs snapshot rpool/root@blank";
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options."com.sun:auto-snapshot" = "false";
          };
          "persist" = {
            type = "zfs_fs";
            mountpoint = "none";
            options."com.sun:auto-snapshot" = "false";
          };
          "persist/apps" = {
            type = "zfs_fs";
            mountpoint = "/persist/apps";
            options."com.sun:auto-snapshot" = "true";
          };
          "persist/cfgs" = {
            type = "zfs_fs";
            mountpoint = "/persist/cfgs";
            options."com.sun:auto-snapshot" = "false";
          };
          "persist/shared" = {
            type = "zfs_fs";
            mountpoint = "/persist/shared";
            options."com.sun:auto-snapshot" = "false";
          };
        };
      };
    };
  };
}