{
  lib,
  config,
  ...
}: let
  cfg = config.modules.services.home-assistant;
in {
  imports = [
    ./core
    ./matter
    ./sgcc
  ];
  options.modules.services.home-assistant = {
    enable = lib.mkEnableOption "home-assistant";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/hass";
    };
  };
  config = {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
    ];
  };
}
