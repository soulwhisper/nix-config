{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.minio;
in
{
  options.modules.services.minio = {
    enable = lib.mkEnableOption "minio";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/minio/data";
    };
    rootCredentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    enableReverseProxy = lib.mkEnableOption "minio-reverseProxy";
    minioURL = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    modules.services.nginx = lib.mkIf cfg.enableReverseProxy {
      enable = true;
      virtualHosts = {
        "${cfg.minioURL}" = {
          enableACME = config.modules.services.nginx.enableAcme;
          acmeRoot = null;
          forceSSL = config.modules.services.nginx.enableAcme;
          extraConfig = ''
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;
            ignore_invalid_headers off;
            chunked_transfer_encoding off;
          '';
          locations."/" = {
            proxyPass = "http://127.0.0.1:9000/";
          };
          locations."/console/" = {
            proxyPass = "http://127.0.0.1:9001/";
            proxyWebsockets = true;
            extraConfig = ''
              rewrite ^/console/(.*) /$1 break;
              real_ip_header X-Real-IP;
            '';
          };
        };
      };
    };

    services.minio = {
      enable = true;
      package = pkgs.unstable.minio;
      dataDir = [
        cfg.dataDir
      ];
      inherit (cfg) rootCredentialsFile;
    };
  };
}
