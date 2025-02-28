{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.minio;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.minio = {
    enable = lib.mkEnableOption "minio";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/minio";
    };
    rootCredentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9000 9001];

    services.caddy.virtualHosts."s3.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      redir /console /console/
      handle_path /console/* {
        reverse_proxy localhost:9001
      }
      handle {
        reverse_proxy localhost:9000
      }
    '';

    systemd.services.minio.environment = {
      MINIO_BROWSER_REDIRECT_URL = "https://s3.noirprime.com/console/";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "d ${cfg.dataDir}/data 0755 appuser appuser - -"
      "d ${cfg.dataDir}/config 0755 appuser appuser - -"
    ];

    services.minio = {
      enable = true;
      package = pkgs.unstable.minio;
      dataDir = [
        "${cfg.dataDir}/data"
      ];
      configDir = "${cfg.dataDir}/config";
      inherit (cfg) rootCredentialsFile;
    };
    systemd.services.minio.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.minio.serviceConfig.Group = lib.mkForce "appuser";
  };
}
