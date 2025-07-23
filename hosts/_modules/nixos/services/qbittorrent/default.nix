{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.qbittorrent;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.qbittorrent = {
    enable = lib.mkEnableOption "qbittorrent";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "bt.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    # 65000 for upnp
    networking.firewall.allowedTCPPorts = [65000] ++ lib.optional (!reverseProxyCaddy.enable) 9807;

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9807
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/media 0755 appuser appuser - -"
      "d /var/lib/media/downloads 0755 appuser appuser - -"
      "d /var/lib/qBittorrent 0755 appuser appuser - -"
    ];

    # user:admin, pass:random-generated

    systemd.services.qbittorrent = {
      description = "Featureful free software BitTorrent client";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.unstable.qbittorrent-nox}/bin/qbittorrent-nox --relative-fastresume --profile=/var/lib --webui-port=9807";
        RuntimeDirectory = "qBittorrent";
        StateDirectory = "qBittorrent";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
