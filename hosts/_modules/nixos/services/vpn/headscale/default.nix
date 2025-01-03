{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.vpn.headscale;
in
{
  options.modules.services.vpn.headscale = {
    enable = lib.mkEnableOption "headscale";
    server_domain = lib.mkOption {
      type = lib.types.str;
      default = "hs.example.com";
    };
    base_domain = lib.mkOption {
      type = lib.types.str;
      default = "ts.example.com";
    };
    certDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ddns";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 443 ];

    modules.services.ddns.enable = true;

    services.headscale = {
      enable = true;
      user = "root";
      group = "root";
      port = 443;
      address = "0.0.0.0";
      settings = {
        tls_key_path = "${cfg.certDir}/${cfg.server_domain}.key";
        tls_cert_path = "${cfg.certDir}/${cfg.server_domain}.cert";
        server_url = "https://${cfg.server_domain}:443";
        dns = {
          base_domain = "${cfg.base_domain}";
          search_domains = [ "homelab.internal" ];
        };
        prefixes = {
          allocation = "sequential";
          v4 = "100.100.0.0/24"; # 100.64.0.0/10
          v6 = "fd7a:115c:a1e0:0:23e0::/116"; # fd7a:115c:a1e0::/48
        };
      };
    };
  };
}
