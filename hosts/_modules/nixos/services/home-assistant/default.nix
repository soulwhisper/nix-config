{lib, ...}: {
  imports = [
    ./core
    ./sgcc
  ];

  options.modules.services.home-assistant = {
    enable = lib.mkEnableOption "home-assistant";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/hass";
    };
  };
}
