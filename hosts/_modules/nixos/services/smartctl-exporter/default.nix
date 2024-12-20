{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.smartctl-exporter;
in
{
  options.modules.services.smartctl-exporter = {
    enable = lib.mkEnableOption "smartctl-exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9101;
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.smartctl = {
      enable = true;
      openFirewall = true;
      inherit (cfg) port;
    };
  };
}
