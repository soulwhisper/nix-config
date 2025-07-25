{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.meshcentral;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.meshcentral = {
    enable = lib.mkEnableOption "meshcentral";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "mesh.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      4433
      (lib.mkIf (!reverseProxyCaddy.enable) 9203)
    ];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9203
      }
    '';

    services.meshcentral = {
      enable = true;
      package = pkgs.unstable.meshcentral;
      settings = {
        settings = {
          agentTimeStampServer = "false";
          aliasPort = 443;
          cert = "${cfg.domain}";
          port = 9203;
          tlsOffload = "127.0.0.1,::1";
        };
        domains = {
          "" = {
            certUrl = "https://${cfg.domain}/";
          };
        };
      };
    };
  };
}
