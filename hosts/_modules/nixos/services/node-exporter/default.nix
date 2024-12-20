{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.node-exporter;
in
{
  options.modules.services.node-exporter = {
    enable = lib.mkEnableOption "node-exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9100;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 9100 ];

    services.prometheus.exporters.node = {
      enable = true;
      inherit (cfg) port;
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "textfile" ];
    };
  };
}
