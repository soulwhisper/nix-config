{
  config,
  lib,
  ...
}: let
  cfg = config.modules.services.nfs4;
in {
  options.modules.services.nfs4 = {
    enable = lib.mkEnableOption "nfs4";
    exports = lib.mkOption {
      type = lib.types.lines;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [2049];

    # NFSv4 only
    services.nfs = {
      server = {
        enable = true;
        inherit (cfg) exports;
        statdPort = 4000;
        lockdPort = 4001;
        mountdPort = 4002;
      };
      settings = {
        nfsd.udp = false;
        nfsd.vers3 = false;
        nfsd.vers4 = true;
        nfsd."vers4.0" = false;
        nfsd."vers4.1" = false;
        nfsd."vers4.2" = true;
      };
    };
  };
}
