{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.talos-api;
in
{
  options.modules.services.talos-api = {
    enable = lib.mkEnableOption "talos-api";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 9300 ];

    systemd.services.talos-api = {
      description = "Talos Cluster Discovery API Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart ="${lib.getExe pkgs.talos-api} -addr=:9300 -landing-addr= -metrics-addr= -snapshot-path=/var/lib/talos-api/state.binpb";
        WorkingDirectory = "/var/lib/talos-api";
        StateDirectory = "talos-api";
        RuntimeDirectory = "talos-api";
        RuntimeDirectoryMode = "0755";
        PrivateTmp = true;
        DynamicUser = true;
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateUsers = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProcSubset = "pid";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
