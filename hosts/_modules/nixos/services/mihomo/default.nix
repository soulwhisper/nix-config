{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.mihomo;
in {
  options.modules.services.mihomo = {
    enable = lib.mkEnableOption "mihomo";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/mihomo";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [1080];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "f ${cfg.dataDir}/config.yaml 0644 appuser appuser - -"
    ];

    # edit/replace config.yaml after deployment; default port = 1080;

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
        AmbientCapabilities = ["CAP_NET_ADMIN"];
        CapabilityBoundingSet = ["CAP_NET_ADMIN"];
        RuntimeDirectory = "mihomo";
        StateDirectory = "mihomo";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
