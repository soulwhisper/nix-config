{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.llm;
in {
  options.modules.services.llm = {
    enable = lib.mkEnableOption "llm";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/llm";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [7861 8501 9997];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "d ${cfg.dataDir}/xinference 0755 appuser appuser - -"
      "d ${cfg.dataDir}/chatbot 0755 appuser appuser - -"
    ];

    hardware.nvidia.nvidiaPersistenced = true;
    hardware.nvidia-container-toolkit.enable = true;

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."llm-xinference" = {
      autoStart = true;
      image = "xprobe/xinference:v0.12.3";
      cmd = ["xinference-local" "-H" "0.0.0.0"];
      extraOptions = ["--device" "nvidia.com/gpu=all"];
      ports = [
        "9997:9997/tcp"
      ];
      environment = {
        PUID = "1001";
        PGID = "1001";
        TZ = "Asia/Shanghai";
      };
      volumes = [
        "${cfg.dataDir}/xinference:/config"
      ];
    };
    virtualisation.oci-containers.containers."llm-chatbot" = {
      autoStart = true;
      image = "chatimage/chatchat:0.3.1.3-93e2c87-20240829";
      ports = [
        "7861:7861/tcp"
        "8501:8501/tcp"
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
