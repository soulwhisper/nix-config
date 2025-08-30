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
    networking.firewall.allowedTCPPorts = [
      9090
      9101
      (lib.mkIf config.modules.filesystems.zfs.enable 9102)
      (lib.mkIf cfg.nut.enable 9103)
      (lib.mkIf cfg.smartd.enable 9104)
      (lib.mkIf cfg.zrepl.enable 9105)
    ];

    services.prometheus = {
      enable = true;
      enableReload = true;
      port = 9090;

      exporters = {
        node = {
          enable = true;
          port = 9101;
          enabledCollectors = ["systemd"];
          disabledCollectors = ["textfile"];
        };
        zfs = lib.mkIf config.modules.filesystems.zfs.enable {
          enable = true;
          port = 9102;
        };
        nut = lib.mkIf cfg.nut.enable {
          enable = true;
          port = 9103;
          nutUser = "upsmon";
          passwordPath = "/etc/nut/password";
        };
        smartctl = lib.mkIf cfg.smartd.enable {
          enable = true;
          port = 9104;
        };
      };
      scrapeConfigs =
        [
          {
            job_name = "node-systemd";
            static_configs = [
              {targets = ["localhost:9101"];}
            ];
          }
        ]
        ++ (
          lib.optional config.modules.filesystems.zfs.enable {
            job_name = "node-zfs";
            static_configs = [
              {targets = ["localhost:9102"];}
            ];
          }
        )
        ++ (
          lib.optional cfg.nut.enable {
            job_name = "node-nut";
            static_configs = [
              {targets = ["localhost:9103"];}
            ];
          }
        )
        ++ (
          lib.optional cfg.smartd.enable {
            job_name = "node-smartd";
            static_configs = [
              {targets = ["localhost:9104"];}
            ];
          }
        )
        ++ (
          lib.optional cfg.zrepl.enable {
            job_name = "node-zrepl";
            static_configs = [
              {targets = ["localhost:9105"];}
            ];
          }
        );
    };
  };
}
