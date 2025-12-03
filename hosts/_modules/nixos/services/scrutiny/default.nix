{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.scrutiny;
in {
  options.modules.services.scrutiny = {
    enable = lib.mkEnableOption "scrutiny";
  };

  config = lib.mkIf cfg.enable {
    # only allow localhost to access influxdb(8086)
    networking.firewall.allowedTCPPorts = [9204];

    services.scrutiny = {
      enable = true;
      settings.web = {
        listen.port = 9204;
        influxdb.host = "127.0.0.1";
      };
    };
  };
}
