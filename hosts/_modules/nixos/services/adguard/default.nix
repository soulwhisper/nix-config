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
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/adguard";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;

    networking.firewall.allowedTCPPorts = [ 53 9200 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
    ];

    services.adguardhome = {
      enable = true;
      mutableSettings = true;
      port = 9200;
      settings = {
        users = [
          {
            name = "admin";
            password = "$2y$10$ufYSEVoSXRPtu4qj2YVIF.wU29hzUqXzRgZoL548.tmblBVT95Rh.";
          }
        ];
        language = "zh-cn";
        theme = "auto";
        dhcp = {
          enabled = false;
        };
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          port = 53;
          upstream_dns = [
            "tls://223.5.5.5"
            "tls://223.6.6.6"
          ];
          bootstrap_dns = [
            "9.9.9.10"
            "149.112.112.10"
            "2620:fe::10"
            "2620:fe::fe:10"
          ];
          fallback_dns = [];
          upstream_mode = "parallel";
          fastest_timeout = "1s";
        };
        filtering = {
          rewrites = [
            { domain = "s3.noirprime.com"; answer = "172.19.82.10"; }
            { domain = "lab.noirprime.com"; answer = "172.19.82.10"; }
            { domain = "mon.noirprime.com"; answer = "172.19.82.10"; }
            { domain = "box.noirprime.com"; answer = "172.19.82.10"; }
            { domain = "pve.homelab.internal"; answer = "172.19.82.100"; }
            { domain = "k8s.homelab.internal"; answer = "172.19.82.101"; }
            { domain = "k8s.homelab.internal"; answer = "172.19.82.102"; }
            { domain = "k8s.homelab.internal"; answer = "172.19.82.103"; }
            { domain = "postgres.noirprime.com"; answer = "172.19.82.201"; }
            { domain = "ingress-int.noirprime.com"; answer = "172.19.82.202"; }
            { domain = "ingress-ext.noirprime.com"; answer = "172.19.82.203"; }
          ];
        };
      };
    };

    systemd.services.adguardhome.serviceConfig.DynamicUser = lib.mkForce false;
    systemd.services.adguardhome.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.adguardhome.serviceConfig.Group = lib.mkForce "appuser";
    systemd.services.adguardhome.serviceConfig.RuntimeDirectory = lib.mkForce "${cfg.dataDir}";
    systemd.services.adguardhome.serviceConfig.StateDirectory = lib.mkForce "${cfg.dataDir}";
  };
}
