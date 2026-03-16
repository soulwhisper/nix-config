{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services;
in {
  options.modules.services.exporters = {
    enable = lib.mkEnableOption "exporters";
  };

  config = lib.mkIf cfg.exporters.enable {
    networking.firewall.allowedTCPPorts =
      [ 9101 ]
      ++ lib.optional config.modules.filesystems.zfs.enable 9102
      ++ lib.optional cfg.nut.enable 9103
      ++ lib.optional cfg.smartd.enable 9104
      ++ lib.optional cfg.zrepl.enable 9105;

    services.prometheus.exporters = {
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
        nutUser = "monuser";
        passwordPath = "/etc/nut/password";
      };
      smartctl = lib.mkIf cfg.smartd.enable {
        enable = true;
        port = 9104;
      };
    };
  };
}
