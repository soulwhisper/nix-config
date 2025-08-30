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
      type = lib.types.attrsOf (
        lib.types.submodule ({name, ...}: {
          options.path = lib.mkOption {
            type = lib.types.str;
            description = "The path to export, cant be empty";
          };
          options.subnet = lib.mkOption {
            type = lib.types.str;
            default = "*";
            description = "The subnet allowed to access";
          };
          options.args = lib.mkOption {
            type = lib.types.str;
            default = "rw,sync,all_squash,anonuid=2000,anongid=2000";
            description = "Export arguments, cant be empty, add 'mountpoint' if using zfs dataset";
          };
        })
      );
      default = {};
      example = {
        default = {
          path = "/var/lib/shared";
          subnet = "*";
          args = "rw,async,all_squash,anonuid=2000,anongid=2000";
        };
      };
      description = "NFS export configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [2049];

    assertions = [
      {
        assertion = lib.all (cfg: cfg.path != "" && cfg.args != "") (lib.attrValues cfg.exports);
        message = "All named NFS exports must have non-empty 'path' and 'args'.";
      }
    ];

    systemd.tmpfiles.rules =
      lib.mapAttrsToList (
        name: cfg: "d ${cfg.path} 0700 2000 2000 - -"
      )
      cfg.exports;

    # NFS user 'shared'
    users.users.shared = {
      group = "shared";
      uid = 2000;
      isSystemUser = true;
    };
    users.groups.shared.gid = 2000;

    # NFSv4 only
    services.nfs = {
      server = {
        enable = true;
        statdPort = 4000;
        lockdPort = 4001;
        mountdPort = 4002;
        exports = let
          exportLines =
            lib.mapAttrsToList (
              name: cfg: "${cfg.path} ${cfg.subnet}(${cfg.args})"
            )
            cfg.exports;
        in
          lib.concatStringsSep "\n" exportLines;
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
