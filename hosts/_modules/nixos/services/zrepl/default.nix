{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.zrepl;
in {
  options.modules.services.zrepl = {
    enable = lib.mkEnableOption "zrepl";
  };

  # use zrepl instead of deprecated autosnapshot;
  # user = root

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9003];

    services.zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "syslog";
              level = "info";
              format = "human";
            }
          ];
          monitoring = [
            {
              type = "prometheus";
              listen = ":9104";
              listen_freebind = true;
            }
          ];
        };
        jobs = [
          {
            # local snapshot and prune only, no replications
            name = "local_snap";
            type = "snap";
            filesystems = {
              "rpool<" = false;
              "rpool/apps<" = true;
            };
            snapshotting = {
              type = "periodic";
              prefix = "zrepl_";
              interval = "12h";
            };
            pruning = {
              keep = [
                {
                  # keep snapshots not created by zrepl
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
                {
                  # keep last 10 snapshots, aka 5 days
                  type = "last_n";
                  count = 10;
                }
              ];
            };
          }
        ];
      };
    };
  };
}
