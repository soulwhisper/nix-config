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
      default = "/persist/apps/talos-api";
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
        ExecStart = "${pkgs.talos-api}/bin/talos-api -addr=:9300 -landing-addr= -metrics-addr= -snapshot-path=${cfg.dataDir}/state.binpb";
        StateDirectory = "talos-api";
        RuntimeDirectory = "talos-api";
        User = "appuser";
        Group = "appuser";
      };
    };
  };
}
