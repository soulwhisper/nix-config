{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.zotregistry;
  reverseProxyCaddy = config.modules.services.caddy;

  # to avoid json lost lines
  configFile = builtins.toFile "config.json" (builtins.readFile ./config.json);
in {
  options.modules.services.zotregistry = {
    enable = lib.mkEnableOption "zotregistry";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/zot"; # "rootDirectory" in config.json
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "zot.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9002]; # "port" in config.json

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9002
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      # "d ${cfg.dataDir}/data 0755 appuser appuser - -"
      "C+ ${cfg.dataDir}/config.json 0600 appuser appuser - ${configFile}"
    ];

    systemd.services.zotregistry = {
      description = "OCI Distribution Registry";
      documentation = ["https://zotregistry.dev/"];
      wants = ["network-online.target"];
      after = ["network-online.target" "local-fs.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStartPre = "${pkgs.zotregistry}/bin/zot verify ${cfg.dataDir}/config.json";
        ExecStart = "${pkgs.zotregistry}/bin/zot serve ${cfg.dataDir}/config.json";
        Restart = "always";
        LimitNOFILE = "500000";
      };
    };

    # systemctl status podman-zotregistry.service
    # modules.services.podman.enable = true;
    # virtualisation.oci-containers.containers."zotregistry" = {
    #   autoStart = true;
    #   image = "ghcr.io/project-zot/zot-linux-amd64:latest";
    #   extraOptions = ["--pull=newer"];
    #   ports = [
    #     "9002:9002/tcp"
    #   ];
    #   environment = {
    #     PUID = "1001";
    #     PGID = "1001";
    #   };
    #   volumes = [
    #    "${cfg.dataDir}/data:/zot/data"
    #     "${cfg.dataDir}/config.json:/etc/zot/config.json"
    #   ];
    # };
  };
}
