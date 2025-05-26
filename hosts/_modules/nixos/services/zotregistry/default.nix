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
      "d /var/lib/zotregistry 0755 appuser appuser - -"
      "C /var/lib/zotregistry/config.json 0600 appuser appuser - ${configFile}"
    ];

    environment.systemPackages = with pkgs; [zotregistry]; # provide zotregistry-cli: zli

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
        ExecStartPre = "${pkgs.zotregistry}/bin/zot verify /var/lib/zotregistry/config.json";
        ExecStart = "${pkgs.zotregistry}/bin/zot serve /var/lib/zotregistry/config.json";
        Restart = "always";
        LimitNOFILE = "500000";
      };
    };
  };
}
