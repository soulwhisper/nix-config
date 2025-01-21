{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.adguard;
  configFile = ./AdGuardHome.yaml;
in {
  options.modules.services.adguard = {
    enable = lib.mkEnableOption "adguard";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/adguard";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;

    networking.firewall.allowedTCPPorts = [53 9200];
    networking.firewall.allowedUDPPorts = [53];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 appuser appuser - -"
      "C+ ${cfg.dataDir}/AdGuardHome.yaml 0700 appuser appuser - ${configFile}"
    ];

    systemd.services.adguardhome = {
      description = "AdGuard Home: Network-level blocker";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 5;
        StartLimitBurst = 10;
      };

      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${lib.getExe pkgs.adguardhome} --no-check-update --pidfile ${cfg.dataDir}/AdGuardHome.pid --work-dir ${cfg.dataDir} --config ${cfg.dataDir}/AdGuardHome.yaml";
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
