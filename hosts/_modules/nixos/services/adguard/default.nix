{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.adguard;
in
{
  options.modules.services.adguard = {
    enable = lib.mkEnableOption "adguard";
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;

    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 67 68 ];

    services.adguardhome = {
      enable = true;
      package = pkgs.unstable.adguardhome;
      port = 3000;
      openFirewall = true;
      mutableSettings = true;
      settings = {
        users = {
          name = "admin";
          password = "$2y$10$ufYSEVoSXRPtu4qj2YVIF.wU29hzUqXzRgZoL548.tmblBVT95Rh.";
        };
        dns = {
          upstream_dns = [
            "tls://223.5.5.5"
            "tls://223.6.6.6"
          ];
        };
        dhcp = {
          enabled = false;
          local_domain_name = "homelab.internal";
          dhcp4 = {
            gateway_ip = "10.10.0.1";
            range_start = "10.10.0.100";
            range_end = "10.10.0.200";
          };
        };
        filtering = {
          rewrites = [
            {   domain = "lab.noirprime.com";
                answer = "10.10.0.10";
            }
            {   domain = "minio.noirprime.com";
                answer = "10.10.0.10";
            }
            {   domain = "s3.noirprime.com";
                answer = "10.10.0.10";
            }
          ];
        };
      };
    };
  };
}
