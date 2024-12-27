{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.exporters;
  exporterConfigs = [
    (lib.mkIf cfg.node.enable {
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
    (lib.mkIf cfg.smartctl.enable {
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
    node.enable = lib.mkEnableOption "node-exporter";
    nut.enable = lib.mkEnableOption "nut-exporter";
    smartctl.enable = lib.mkEnableOption "smartctl-exporter";
  };

  config = lib.fold lib.recursiveUpdate {} exporterConfigs;
}
