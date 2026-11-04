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

  # spec: 4C8G, 1TB, ESXi VM;

  config = {
    # This is a must if "/home" is isolated from "/", for sops.
    fileSystems."/home".neededForBoot = true;

    # services.qemuGuest.enable = true;
    virtualisation.vmware.guest.enable = true;

    services = {
      pki = {
        enable = true;
        rootCertificateFile = config.sops.secrets."pki/root-ca-crt".path;
        intermediateCertificateFile = config.sops.secrets."pki/intermediate-crt".path;
        intermediateKeyFile = config.sops.secrets."pki/intermediate-key".path;
        intermediatePasswordFile = config.sops.secrets."pki/intermediate-password".path;
        backup = {
          recipient = "age1qlugfu60vrhgqtuw0kqqtks9p7nz9npnwa255j7w27t3gapcdv6qjptd7d";
          identityFile = "/run/corp-service-backup/identity.txt";
        };
      };
      forgejo = {
        enable = true;
        domain = "git.internal.htkrail.com";
        backup = {
          recipient = "age1qlugfu60vrhgqtuw0kqqtks9p7nz9npnwa255j7w27t3gapcdv6qjptd7d";
          identityFile = "/run/corp-service-backup/identity.txt";
        };
      };
    };

    modules = {
      filesystems.xfs.enable = true;
      services = {
        adguard.enable = true;
        caddy.enable = true;
        caddy.cloudflare.enable = false;

        # : Networking
        easytier.networks = [
          "172.19.82.0/24"
        ];
        tailscale.enable = true;

        # : Monitoring
        scrutiny.enable = false;
        smartd.enable = false;
        nut.enable = false;

        # : Main
        versitygw.enable = true; # ep=:9000,9001
        versitygw.authFile = config.sops.secrets."storage/versitygw/auth".path;

        # : TEST
        netbox.enable = false; # sub=box

        # : Others
        kms.enable = true;
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
