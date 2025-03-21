{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.backup.zrepl;
in {
  options.modules.services.backup.zrepl = {
    enable = lib.mkEnableOption "zrepl";
  };

  # backup zfs pools between sites
  # this template needs tailscale / wireguard for tcp transport;
  # user = root, files in zfs pool

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9003 9103];

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
              listen = ":9103";
              listen_freebind = true;
            }
          ];
        };
        jobs = [
          {
            name = "site_snap";
            type = "snap";
            filesystems = {
              "numina<" = false;
              "numina/backup<" = false;
              "numina/media<" = false;
              "numina/docs<" = true;
              "numina/apps<" = true;
              "numina/timemachine<" = false;
              "numina/replication<" = false;
            };
            snapshotting = {
              type = "periodic";
              prefix = "zrepl_";
              interval = "6h";
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
                  type = "last_n";
                  count = 1;
                }
                {
                  # of the last 24 hours keep all snapshots
                  # of the last 7 days keep 1 snapshot each day
                  # of the last 30 days keep 1 snapshot each day
                  # of the last 6 months keep 1 snapshot each month
                  # DEACT of the last 1 year keep 1 snapshot each year
                  # discard the rest
                  # details see: https://zrepl.github.io/configuration/prune.html#policy-grid
                  type = "grid";
                  grid = "1x24h(keep=all) | 7x1d(keep=1) | 30x1d(keep=1) | 6x30d(keep=1)";
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
          {
            name = "local_source";
            type = "source";
            serve = {
              type = "tcp";
              listen = "0.0.0.0:9003";
              clients = {
                "10.100.0.0/24" = "backup-*";
              };
            };
            filesystems = {
              "numina<" = true;
              "numina/timemachine<" = false;
              "numina/replication<" = false;
            };
            snapshotting = {
              type = "manual";
            };
          }
          {
            name = "remote_pull";
            type = "pull";
            connect = {
              type = "tcp";
              # change this addr accordingly
              address = "10.100.0.10:9003";
            };
            root_fs = "numina/replication";
            interval = "10m";
            pruning = {
              keep_sender = [
                {
                  # keep snapshots not created by zrepl
                  type = "regex";
                  negate = true;
                  regex = "^zrepl_.*";
                }
                {
                  type = "not_replicated";
                }
                {
                  type = "last_n";
                  count = 1;
                }
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h(keep=1) | 14x1d(keep=1)";
                  regex = "^zrepl_.*";
                }
              ];
              keep_receiver = [
                {
                  type = "grid";
                  grid = "1x24h(keep=all) | 7x1d(keep=1) | 30x1d(keep=1) | 6x30d(keep=1)";
                  regex = "^zrepl_.*";
                }
              ];
            };
          }
        ];
      };
    };
  };
}
