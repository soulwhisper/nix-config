{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.llm;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.llm = {
    enable = lib.mkEnableOption "llm";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/llm";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9803];

    services.caddy.virtualHosts."chat.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9803
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "d ${cfg.dataDir}/chatbot 0755 appuser appuser - -"
      "d ${cfg.dataDir}/models 0755 appuser appuser - -"
      "d ${cfg.dataDir}/ollama 0755 appuser appuser - -"
    ];

    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
      models = "${cfg.dataDir}/models";
      home = "${cfg.dataDir}/ollama";
      user = "appuser";
      group = "appuser";
      loadModels = ["deepseek-r1:8b"];
    };

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."llm-chatbot" = {
      autoStart = true;
      image = "chatimage/chatchat:0.3.1.3-93e2c87-20240829";
      ports = [
        "7861:7861/tcp" # api
        "9803:8501/tcp" # web
      ];
      environment = {
        PUID = "1001";
        PGID = "1001";
        TZ = "Asia/Shanghai";
      };
      volumes = [
        "${cfg.dataDir}/chatbot:/root/chatchat_data"
      ];
    };
  };
}
