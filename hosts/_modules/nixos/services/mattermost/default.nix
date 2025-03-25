{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.mattermost;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.mattermost = {
    enable = lib.mkEnableOption "mattermost";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9801];

    services.caddy.virtualHosts."lab.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9801
      }
    '';

    # persist postgres data
    modules.services.postgresql.enable = true;

    services.mattermost = {
      enable = true;
      listenAddress = "[::]:9801";
      siteName = "Homelab";
      siteUrl = "http://lab.noirprime.com";
      matterircd = {
        enable = true;
        parameters = [
          "-mmserver lab.noirprime.com"
          "-bind [::]:6667"
        ];
      };
    };
  };
}
