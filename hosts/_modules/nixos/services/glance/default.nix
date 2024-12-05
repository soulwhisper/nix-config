{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.glance;
in
{
  options.modules.services.glance = {
    enable = lib.mkEnableOption "glance";
  };

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."lab.noirprime.com".extraConfig = ''
      handle {
	      reverse_proxy localhost:9802
      }
    '';

    # networking.firewall.allowedTCPPorts = [ 9802 ];

    environment.etc = {
        "glance/glance.yaml".source = pkgs.writeTextFile {
        name = "glance.yaml";
        text = builtins.readFile ./glance.yaml;
        };
        "glance/glance.yaml".mode = "0755";
    };

    systemd.services.glance = {
      description = "Glance feed dashboard server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart ="${lib.getExe pkgs.unstable.glance} --config /etc/glance/glance.yaml";
        WorkingDirectory = "/var/lib/glance";
        StateDirectory = "glance";
        RuntimeDirectory = "glance";
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
