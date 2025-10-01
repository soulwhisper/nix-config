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

  # spec: 4C8G, 500GB, ESXi VM;

  config = {
    # services.qemuGuest.enable = true;
    virtualisation.vmware.guest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = true;
        caddy.enable = true;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;
        easytier.proxy_networks = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];

        # : System
        smartd.enable = false;
        nut.enable = true;

        # : K8S Prod
        meshcentral.enable = true; # sub=mesh
        talos.api.enable = true;
        versitygw.enable = true; # ep=:7070
        versitygw.authFile = config.sops.secrets."storage/versitygw/auth".path;

        # : LAB
        home-assistant.enable = true; # sub=hass
        kms.enable = true;
        netbox.enable = true; # sub=box
        unifi-controller.enable = true; # sub=unifi

        # : Others
        nfs4 = {
          enable = true; # all_squash = 2000:2000
          exports.default = {
            path = "/var/lib/shared";
            subnet = "10.10.0.0/24";
          };
        };
        sftpgo.enable = true;
        timemachine.enable = false;
      };
    };
  };
}
