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

  # spec: 4C8G, 100GB, Proxmox VM;

  config = {
    services.qemuGuest.enable = true;

    modules = {
      filesystems.xfs.enable = true;
      services = {
        # : Networking
        mosdns.enable = true;
        singbox.enable = true;
        singbox.subscription = config.sops.secrets."networking/proxy/subscription".path;
        # easytier.proxy_networks = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];

        # : Monitoring
        smartd.enable = false;
        nut.enable = false;

        # : K8S Prod
        meshcentral.enable = true; # ep=:9203
        talos.api.enable = true; # ep=:9300
        garage.enable = true; # ep=:9000

        # : LAB
        unifi-controller.enable = true; # ep=:8443

        # : Others
        nfs4 = {
          enable = true; # all_squash = 2000:2000
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
