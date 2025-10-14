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
        # : Networking
        mihomo.enable = true;
        mihomo.subscription = config.sops.secrets."networking/proxy/subscription".path;
        easytier.proxy_networks = ["10.0.0.0/24" "10.10.0.0/24" "10.20.0.0/24"];

        # : Monitoring
        smartd.enable = false;
        nut.enable = true;

        # : K8S Prod
        meshcentral.enable = true; # ep=:9203
        talos.api.enable = true; # ep=:9300
        versitygw.enable = true; # ep=:7070
        versitygw.authFile = config.sops.secrets."storage/versitygw/auth".path;

        # : LAB
        home-assistant.enable = true; # ep=:8123
        kms.enable = true; # ep=:1688
        unifi-controller.enable = true; # ep=:8443

        # : Others
        nfs4 = {
          enable = true; # all_squash = 2000:2000
          exports= {
            media = {
              path = "/var/lib/shared/media";
              subnet = "10.10.0.0/24";
            };
            volsync = {
              path = "/var/lib/shared/volsync";
              subnet = "10.10.0.0/24";
            };
          };
        };
        sftpgo.enable = true;
        timemachine.enable = false;
      };
    };
  };
}
