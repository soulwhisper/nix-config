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
    domain = lib.mkOption {
      type = lib.types.str;
      default = "s3.noirprime.com";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # deprecated, use versityGateway instead
  # last available version = `RELEASE.2025-04-22T22-12-26Z`
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/servers/minio/default.nix#L33

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9000 9001];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
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
      "d /var/lib/minio 0755 appuser appuser - -"
      "d /var/lib/minio/data 0755 appuser appuser - -"
      "d /var/lib/minio/config 0755 appuser appuser - -"
    ];

    services.minio = {
      enable = true;
      package = pkgs.minio;
      dataDir = [
        "/var/lib/minio/data"
      ];
      configDir = "/var/lib/minio/config";
      rootCredentialsFile = cfg.authFile;
    };
    systemd.services.minio.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.minio.serviceConfig.Group = lib.mkForce "appuser";
  };
}
