{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.qbittorrent;
  reverseProxyCaddy = config.modules.services.caddy;
  configFile = ./qBittorrent.conf;
in {
  options.modules.services.qbittorrent = {
    enable = lib.mkEnableOption "qbittorrent";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "bt.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [65000] ++ lib.optional (!reverseProxyCaddy.enable) 9807;

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9807
      }
    '';

    systemd.tmpfiles.rules = [
      "d /var/lib/media 0755 appuser appuser - -"
      "d /var/lib/media/downloads 0755 appuser appuser - -"
      "d /var/lib/qbittorrent 0755 appuser appuser - -"
      "d /var/lib/qbittorrent/config 0755 appuser appuser - -"
      "C /var/lib/qbittorrent/config/qBittorrent.conf 0700 appuser appuser - ${configFile}"
    ];

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
        ExecStart = "${pkgs.unstable.qbittorrent-nox}/bin/qbittorrent-nox --profile=/var/lib/qbittorrent/config --relative-fastresume --webui-port=9807";
        RuntimeDirectory = "qbittorrent";
        StateDirectory = "qbittorrent";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
