{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.postgres;
in {
  options.modules.services.postgres = {
    enable = lib.mkEnableOption "postgres";
  };

  # this service will add support for app development
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [5432 9500];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
      enableTCPIP = true;
      ensureDatabases = ["postgres"];
      ensureUsers = [
        {
          name = "postgres";
          ensureDBOwnership = true;
        }
      ];
      extensions = ps:
        with ps; [
          hypopg
          pg_auto_failover
          pg_cron
          pg_tle
          pg_net
          pg_repack
          pg_safeupdate
          pg_uuidv7
          pgaudit
          pgmq
          pgroonga
          pgrouting
          pgsql-http
          pgsodium
          pgtap
          pgvector
          plpgsql_check
          postgis
          rum
          tds_fdw
          timescaledb
          timescaledb_toolkit
          wal2json
        ];
      settings.shared_preload_libraries = [
        "pg_cron"
        "pg_net"
        "pg_tle"
        "pgaudit"
        "pgautofailover"
        "pgsodium"
        "plpgsql_check"
        "safeupdate"
        "timescaledb"
      ];
      initialScript = pkgs.writeText "init-sql-script" ''
        CREATE EXTENSION IF NOT EXISTS http;
        CREATE EXTENSION IF NOT EXISTS hypopg;
        CREATE EXTENSION IF NOT EXISTS pg_net;
        CREATE EXTENSION IF NOT EXISTS pg_repack;
        CREATE EXTENSION IF NOT EXISTS pg_tle;
        CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
        CREATE EXTENSION IF NOT EXISTS pgautofailover CASCADE;
        CREATE EXTENSION IF NOT EXISTS pgmq;
        CREATE EXTENSION IF NOT EXISTS pgroonga;
        CREATE EXTENSION IF NOT EXISTS pgrouting CASCADE;
        CREATE EXTENSION IF NOT EXISTS pgsodium;
        CREATE EXTENSION IF NOT EXISTS pgtap;
        CREATE EXTENSION IF NOT EXISTS plpgsql_check CASCADE;
        CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS rum;
        CREATE EXTENSION IF NOT EXISTS tds_fdw;
        CREATE EXTENSION IF NOT EXISTS timescaledb;
        CREATE EXTENSION IF NOT EXISTS timescaledb_toolkit;
        CREATE EXTENSION IF NOT EXISTS vector;
      '';
    };

    services.postgrest = {
      enable = true;
      settings = {
        server-host = "0.0.0.0";
        server-port = 9500;
        server-unix-socket = null;
        db-uri.host = "localhost";
        db-uri.dbname = "postgres";
      };
    };

    services.postgresqlBackup = {
      enable = true;
      location = "/mnt/shared/backup/postgres";
    };
  };
}
