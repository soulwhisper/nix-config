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
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9300];

    systemd.tmpfiles.rules = [
      "d /var/lib/talos-api 0755 appuser appuser - -"
      "f /var/lib/talos-api/state.binpb 0755 appuser appuser - -"
    ];

    systemd.services.talos-api = {
      description = "Talos Cluster Discovery API Service";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStart = "${pkgs.talos-api}/bin/talos-api -addr=:9300 -landing-addr= -metrics-addr= -snapshot-path=/var/lib/talos-api/state.binpb";
        User = "appuser";
        Group = "appuser";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
