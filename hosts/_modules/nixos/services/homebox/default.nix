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
      default = "/opt/apps/homebox";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."box.noirprime.com".extraConfig = ''
      handle {
        reverse_proxy localhost:9803
      }
    '';

    # networking.firewall.allowedTCPPorts = [ 9803 ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0644 appuser appuser - -"
    ];

    systemd.services.homebox = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
	      HBOX_STORAGE_DATA = "${cfg.dataDir}";
	      HBOX_STORAGE_SQLITE_URL = "${cfg.dataDir}/homebox.db?_pragma=busy_timeout=999&_pragma=journal_mode=WAL&_fk=1";
	      HBOX_WEB_PORT = "9803";
	      HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
	      HBOX_WEB_MAX_UPLOAD_SIZE = "100";
	      HBOX_MODE = "production";
      };
      serviceConfig = {
        ExecStart = lib.getExe pkgs.unstable.homebox;
        WorkingDirectory = "${cfg.dataDir}";
        User = "appuser";
        Group = "appuser";
        Restart = "always";
      };
    };
  };
}
