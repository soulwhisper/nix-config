{
  lib,
  config,
  ...
}:
let
  cfg = config.modules.services.nfs;
in
{
  options.modules.services.nfs = {
    enable = lib.mkEnableOption "nfs";
    exports = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nfs.server = {
      enable = true;
      inherit (cfg) exports;
      statdPort = 4000;
      lockdPort = 4001;
      mountdPort = 4002;
    };

    networking.firewall.allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
    networking.firewall.allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
  };
}
