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
    domain = lib.mkOption {
      type = lib.types.str;
      default = "git.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9003 9004];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9003
      }
    '';

    environment.systemPackages = [
      pkgs.forgejo-cli
    ];

    services.forgejo = {
      enable = true;
      user = "appuser";
      group = "appuser";
      stateDir = "/var/lib/forgejo";
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = "git.noirprime.com";
          ROOT_URL = "https://git.noirprime.com/";
          HTTP_PORT = 9003;
          SSH_PORT = 9004;
        };
        proxy = {
          PROXY_ENABLED = "true";
          PROXY_URL = "http://127.0.0.1:1080";
          PROXY_HOSTS = "*.github.com,github.com,raw.githubusercontent.com";
        };
        migrations = {
          ALLOW_LOCALNETWORKS = "true";
        };
      };
    };
  };
}
