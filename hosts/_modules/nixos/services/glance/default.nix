{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.glance;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.glance = {
    enable = lib.mkEnableOption "glance";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/glance";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9802];

    services.caddy.virtualHosts."lab.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
       reverse_proxy localhost:9802
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
    ];

    environment.etc = {
      "glance/glance.yaml".source = pkgs.writeTextFile {
        name = "glance.yaml";
        text = builtins.readFile ./glance.yaml;
      };
      "glance/glance.yaml".mode = "0755";
    };

    systemd.services.glance = {
      description = "Glance feed dashboard server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.unstable.glance} --config /etc/glance/glance.yaml";
        StateDirectory = "${cfg.dataDir}";
        RuntimeDirectory = "${cfg.dataDir}";
        User = "appuser";
        Group = "appuser";
      };
    };
  };
}
