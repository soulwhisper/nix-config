{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.uptime;
in
{
  options.modules.services.uptime = {
    enable = lib.mkEnableOption "uptime";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/uptime";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."mon.noirprime.com".extraConfig = ''
      handle {
	      reverse_proxy localhost:9801
      }
    '';

    # networking.firewall.allowedTCPPorts = [ 9801 ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
    ];

    systemd.services.uptime-kuma = {
      description = "Uptime Kuma";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        DATA_DIR="${cfg.dataDir}";
        NODE_ENV="production";
        UPTIME_KUMA_HOST="0.0.0.0";
        UPTIME_KUMA_PORT="9801";
        UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN="true";
        UPTIME_KUMA_WS_ORIGIN_CHECK="bypass";
      };
      path = with pkgs; [ unixtools.ping apprise ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.uptime-kuma}";
        Restart = "on-failure";
        User = "appuser";
        Group = "appuser";
      };
    };
  };
}
