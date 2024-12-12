{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.discovery-api;
in
{
  options.modules.services.discovery-api = {
    enable = lib.mkEnableOption "discovery-api";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 9900 ];

    systemd.services.discovery-api = {
      description = "Talos Cluster Discovery API Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart ="${lib.getExe pkgs.discovery-api} -addr=:9900 -landing-addr= -metrics-addr= -snapshot-path=/var/lib/discovery-api/state.binpb";
        WorkingDirectory = "/var/lib/discovery-api";
        StateDirectory = "discovery-api";
        RuntimeDirectory = "discovery-api";
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
