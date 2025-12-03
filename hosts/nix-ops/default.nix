{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./secrets.nix
  ];

  # spec: 4C8G, 1TB, ESXi VM;

  config = {
    # This is a must if "/home" is isolated from "/", for sops.
    fileSystems."/home".neededForBoot = true;

    virtualisation.vmware.guest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = true;
        caddy.enable = true;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;

        # : Networking
        easytier.proxy_networks = ["172.19.80.0/24" "172.19.82.0/24"];

        # : Monitoring
        scrutiny.enable = false;
        smartd.enable = false;
        nut.enable = false;

        # : Test
        unifi-server.enable = true; # ep=:9801
        unifi-server.ip = "172.19.82.10";

        # : LAB
        garage.enable = true; # ep=:9000
        kms.enable = true;
        talos.api.enable = true;
        netbox.enable = true; # sub=box

        # : Others
        nfs4 = {
          enable = true; # all_squash = 2000:2000
          exports.default = {
            path = "/var/lib/shared";
            subnet = "172.19.82.0/24";
          };
        };
      };
    };
  };
}
