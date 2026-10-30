{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  # spec: N100 4C32G, 1TB;

  config = {
    # This is a must if "/home" is isolated from "/", for sops.
    fileSystems."/home".neededForBoot = true;

    # services.qemuGuest.enable = true;
    # virtualisation.vmware.guest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = false;
        caddy.enable = false;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;

        # : Networking
        tailscale.enable = false;

        # : Monitoring
        scrutiny.enable = false;
        smartd.enable = false;
        nut.enable = false;

        # : Main
        versitygw.enable = false; # ep=:9000,9001
        versitygw.authFile = config.sops.secrets."storage/versitygw/auth".path;

        # : TEST
        netbox.enable = false; # sub=box

        # : Others
        kms.enable = false;
        nfs4 = {
          enable = false; # all_squash = 2000:2000
          exports.default = {
            path = "/var/lib/shared";
            subnet = "172.19.82.0/24";
          };
        };
      };
    };
  };
}
