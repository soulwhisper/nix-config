{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.n8n;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.n8n = {
    enable = lib.mkEnableOption "n8n";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "n8n.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9800];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9800
      }
    '';

    services.n8n = {
      enable = true;
      webhookUrl = "https://${cfg.domain}";
      settings.port = lib.mkForce 9800;
    };
    systemd.services.n8n.serviceConfig.ExecStart = lib.mkForce "${pkgs.unstable.n8n}/bin/n8n";
  };
}
