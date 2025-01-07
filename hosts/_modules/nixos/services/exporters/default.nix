{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services;
  exporterConfigs = [
    (lib.mkIf cfg.exporters.enable {
      networking.firewall.allowedTCPPorts = [ 9100 ];

      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [ "systemd" ];
        disabledCollectors = [ "textfile" ];
      };
    })
    (lib.mkIf cfg.nut.enable {
      networking.firewall.allowedTCPPorts = [ 9101 ];

      services.prometheus.exporters.nut = {
        enable = true;
        port = 9101;
        nutUser = "upsmon";
        passwordPath = "/etc/nut/password";
      };
    })
    (lib.mkIf cfg.smartd.enable {
      networking.firewall.allowedTCPPorts = [ 9102 ];

      services.prometheus.exporters.smartctl = {
        enable = true;
        port = 9102;
      };
    })
  ];
in
{
  options.modules.services.exporters = {
    enable = lib.mkEnableOption "node-exporter";
  };

  config = lib.fold lib.recursiveUpdate {} exporterConfigs;
}
