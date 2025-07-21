{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.freshrss;
in {
  options.modules.services.freshrss = {
    enable = lib.mkEnableOption "freshrss";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "rss.noirprime.com";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    # caddy virtualHost managed by service, no ports exposed;

    services.freshrss = {
      enable = true;
      baseUrl = "https://${cfg.domain}";
      dataDir = "/var/lib/freshrss";
      webserver = "caddy";
      virtualHost = "${cfg.domain}";
      passwordFile = cfg.authFile; # user=admin
      user = "appuser";
    };
  };
}
