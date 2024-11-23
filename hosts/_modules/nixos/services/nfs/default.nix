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
    };

    networking.firewall.allowedTCPPorts = [ 111 2049 ];
    networking.firewall.allowedUDPPorts = [ 111 2049 ];
  };
}
