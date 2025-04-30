{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.mihomo;
  configFile = ./config.yaml;
in {
  options.modules.services.mihomo = {
    enable = lib.mkEnableOption "mihomo";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/mihomo";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [1080 9201];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "C ${cfg.dataDir}/config.yaml 0644 appuser appuser - ${configFile}"
    ];

    systemd.services.mihomo = {
      description = "Mihomo daemon, A rule-based proxy in Go.";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.unstable.mihomo}/bin/mihomo -d /var/lib/mihomo -f ${cfg.dataDir}/config.yaml -ext-ui ${pkgs.metacubexd}";
        # below for tun
        # AmbientCapabilities = ["CAP_NET_ADMIN"];
        # CapabilityBoundingSet = ["CAP_NET_ADMIN"];
        RuntimeDirectory = "mihomo";
        StateDirectory = "mihomo";
        Restart = "always";
        RestartSec = 5;
        EnvironmentFile = [
          "${cfg.authFile}"
        ];
      };
    };
  };
}
