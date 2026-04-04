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

    # services.qemuGuest.enable = true;
    virtualisation.vmware.guest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        # adguard.enable = true;
        caddy.enable = true;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;

        # : Networking
        easytier.networks = ["172.19.80.0/24" "172.19.82.0/24"];

        # : Monitoring
        scrutiny.enable = false;
        smartd.enable = false;
        nut.enable = false;

        # : TEST
        kms.enable = true;
        isc.enable = true;
        isc.bind.authFile = config.sops.secrets."networking/bind/auth".path;

        garage.enable = false; # ep=:9000
        talos.api.enable = false;
        netbox.enable = false; # sub=box
        unifi-server.enable = false; # sub=unifi

        # : Others
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
