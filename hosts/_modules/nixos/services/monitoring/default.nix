{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services;
in {
  options.modules.services.monitoring = {
    enable = lib.mkEnableOption "monitoring";
  };

  config = lib.mkIf cfg.monitoring.enable {
    networking.firewall.allowedTCPPorts = [9090];

    services.prometheus = {
      enable = true;
      port = 9090;

      exporters = {
        node = {
          enable = true;
          port = 9100;
          enabledCollectors = ["systemd"];
          disabledCollectors = ["textfile"];
        };
        nut = lib.mkIf cfg.nut.enable {
          enable = true;
          port = 9101;
          nutUser = "upsmon";
          passwordPath = "/etc/nut/password";
        };
        smartctl = lib.mkIf cfg.smartd.enable {
          enable = true;
          port = 9102;
        };
      };
      scrapeConfigs =
        [
          {
            job_name = "node-systemd";
            static_configs = [
              {targets = ["localhost:9100"];}
            ];
          }
        ]
        ++ (
          lib.optional cfg.nut.enable {
            job_name = "node-nut";
            static_configs = [
              {targets = ["localhost:9101"];}
            ];
          }
        )
        ++ (
          lib.optional cfg.smartd.enable {
            job_name = "node-smartd";
            static_configs = [
              {targets = ["localhost:9102"];}
            ];
          }
        );
    };
  };
}
