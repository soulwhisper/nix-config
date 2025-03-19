{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.forgejo;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.forgejo = {
    enable = lib.mkEnableOption "forgejo";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/forgejo";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9003 9004];

    services.caddy.virtualHosts."git.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9003
      }
    '';

    services.forgejo = {
      enable = true;
      user = "appuser";
      group = "appuser";
      stateDir = "${cfg.dataDir}";
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = "git.noirprime.com";
          HTTP_PORT = 9003;
          SSH_PORT = 9004;
        };
      };
    };
  };
}
