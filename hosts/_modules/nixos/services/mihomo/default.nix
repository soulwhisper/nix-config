{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.mihomo;
in {
  options.modules.services.mihomo = {
    enable = lib.mkEnableOption "mihomo";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/mihomo";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [1080 9201]; # webui=9201

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 appuser appuser - -"
      "f ${cfg.dataDir}/mihomo.yaml 0600 appuser appuser - -"
    ];

    services.mihomo = {
      enable = true;
      package = pkgs.unstable.mihomo;
      webui = pkgs.metacubexd;
      tunMode = true;
      configFile = "${cfg.dataDir}/mihomo.yaml";
    };
  };
}
