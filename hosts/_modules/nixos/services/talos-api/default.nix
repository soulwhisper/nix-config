{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.talos.api;
in {
  options.modules.services.talos.api = {
    enable = lib.mkEnableOption "talos-api";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/talos-api";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9300];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "f ${cfg.dataDir}/state.binpb 0755 appuser appuser - -"
    ];

    systemd.services.talos-api = {
      description = "Talos Cluster Discovery API Service";
      wants = ["network-online.target"];
      after = ["network-online.target"];

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.talos-api} -addr=:9300 -landing-addr= -metrics-addr= -snapshot-path=${cfg.dataDir}/state.binpb";
        StateDirectory = "${cfg.dataDir}";
        RuntimeDirectory = "${cfg.dataDir}";
        User = "appuser";
        Group = "appuser";
      };
    };
  };
}
