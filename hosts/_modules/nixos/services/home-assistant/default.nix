{
  config,
  lib,
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
  };
  config = {
    systemd.tmpfiles.rules = [
      "d /var/lib/hass 0755 appuser appuser - -"
    ];
  };
}
