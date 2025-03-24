{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.ollama;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.ollama = {
    enable = lib.mkEnableOption "ollama";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/ollama";
    };
    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9400];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
    ];

    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
      host = "0.0.0.0";
      port = 9400;
      models = "${cfg.dataDir}";
      user = "appuser";
      group = "appuser";
      loadModels = cfg.models;
    };
  };
}
