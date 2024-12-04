{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.homebox;
in
{
  options.modules.services.homebox = {
    enable = lib.mkEnableOption "homebox";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/homebox/data";
    };
    enableReverseProxy = lib.mkEnableOption "homebox-reverseProxy";
    homeboxURL = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    modules.services.nginx = lib.mkIf cfg.enableReverseProxy {
      enable = true;
      virtualHosts = {
        "${cfg.homeboxURL}" = {
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
            proxyPass = "http://127.0.0.1:7745/";
          };
        };
      };
    };

    services.homebox = {
      enable = true;
      package = pkgs.unstable.homebox;
      settings = {
	      HBOX_STORAGE_DATA = "${cfg.dataDir}";
	      HBOX_STORAGE_SQLITE_URL = "${cfg.dataDir}/homebox.db?_pragma=busy_timeout=999&_pragma=journal_mode=WAL&_fk=1";
	      HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
        HBOX_WEB_MAX_UPLOAD_SIZE = "100";
		    HBOX_MODE = "production";
	    };
    };
  };
}
