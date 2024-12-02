{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf types;
  cfg = config.modules.services.glance;
in
{
  options.modules.services.glance = {
    enable = lib.mkEnableOption "glance";
    enableReverseProxy = lib.mkEnableOption "glance-reverseProxy";
    glanceURL = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    modules.services.nginx = lib.mkIf cfg.enableReverseProxy {
      enable = true;
      virtualHosts = {
        "${cfg.glanceURL}" = {
          enableACME = config.modules.services.nginx.enableAcme;
          acmeRoot = null;
          forceSSL = config.modules.services.nginx.enableAcme;
          extraConfig = ''
            client_max_body_size 0;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
          locations."/" = {
            proxyPass = "http://127.0.0.1:8000/";
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

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
