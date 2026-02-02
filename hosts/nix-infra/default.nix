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

  # Spec: 4C8G, 100GB, Proxmox VM;
  # Address: 10.0.0.200;

  config = {
    services.qemuGuest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = true;
        caddy.enable = true;
        caddy.authFile = config.sops.secrets."networking/cloudflare/auth".path;

        # : Networking
        # easytier.proxy_networks = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];

        # : Monitoring
        scrutiny.enable = false;
        smartd.enable = false;
        nut.enable = false;

        # : Infrastructure
        gatus.enable = true; # ep=:9400
        gatus.pushover.authFile = config.sops.secrets."alerting/pushover/auth".path;
        unifi-server.enable = true; # sub=unifi
        vector.enable = true; # ep=:514

        # : Services migrated to NAS
        garage.enable = false; # ep=:9000
        meshcentral.enable = false; # ep=:9203
        talos.api.enable = false; # ep=:9300

        nfs4 = {
          enable = false; # all_squash = 2000:2000
          exports.default = {
            path = "/var/lib/shared";
            subnet = "10.10.0.0/24";
          };
        };
        sftpgo.enable = false;
        timemachine.enable = false;
      };
    };
  };
}
