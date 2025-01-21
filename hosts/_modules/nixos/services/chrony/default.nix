{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.chrony;
in {
  options.modules.services.chrony = {
    enable = lib.mkEnableOption "chrony";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/chrony"; # owned by chrony:chrony
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [323];

    services.chrony = {
      enable = true;
      package = pkgs.unstable.chrony;
      directory = "${cfg.dataDir}";
      servers = [
        "ntp.ntsc.ac.cn"
        "ntp.aliyun.com"
        "cn.pool.ntp.org"
      ];
      extraConfig = ''
        allow all
        bindaddress 0.0.0.0
      '';
    };
  };
}
