{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.chrony;
in
{
  options.modules.services.chrony = {
    enable = lib.mkEnableOption "chrony";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ 323 ];

    services.chrony = {
      enable = true;
      package = pkgs.unstable.chrony;
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
