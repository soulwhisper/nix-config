{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.adguard;
  configFile = ./AdGuardHome.yaml;
in {
  options.modules.services.adguard = {
    enable = lib.mkEnableOption "adguard";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/adguard";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    networking.firewall.allowedTCPPorts = [53 9200];
    networking.firewall.allowedUDPPorts = [53];

    # official service is not working

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 appuser appuser - -"
      "C+ ${cfg.dataDir}/AdGuardHome.yaml 0700 appuser appuser - ${configFile}"
    ];

    # Avoiding the trap: the start limit
    # [Unit]
    # StartLimitBurst=5
    # StartLimitIntervalSec=10
    # with `Restart=always`, systemd gives up restarting your service 
    # if it fails to start more than 5 times within a 10 seconds interval. Forever.
    # fix:
    # [Unit]
    # StartLimitIntervalSec=0

    systemd.services.adguardhome = {
      description = "AdGuard Home: Network-level blocker";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.adguardhome}/bin/adguardhome --no-check-update --pidfile /run/AdGuardHome/AdGuardHome.pid --work-dir /var/lib/AdGuardHome --config ${cfg.dataDir}/AdGuardHome.yaml";
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        RuntimeDirectory = "AdGuardHome";
        StateDirectory = "AdGuardHome";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
