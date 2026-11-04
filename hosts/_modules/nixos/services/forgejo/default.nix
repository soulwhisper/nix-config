{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo;
  pg = pkgs.postgresql_18;
  pgData = "/var/lib/postgresql-forgejo/18";
  socket = "/run/postgresql-forgejo";
  domain = cfg.settings.server.DOMAIN or "git.internal.htkrail.com";
  hba = pkgs.writeText "forgejo-pg_hba.conf" ''
    local forgejo forgejo peer
    local all forgejo-db-admin peer map=forgejo-admin
    local replication all reject
    local all all reject
    host replication all 0.0.0.0/0 reject
    host replication all ::0/0 reject
    host all all 0.0.0.0/0 reject
    host all all ::0/0 reject
  '';
  ident = pkgs.writeText "forgejo-pg_ident.conf" ''
    forgejo-admin postgres-forgejo forgejo-db-admin
  '';
  pgConfig = pkgs.writeText "forgejo-postgresql.conf" ''
    data_directory = '${pgData}'
    hba_file = '${hba}'
    ident_file = '${ident}'
    listen_addresses = '${""}'
    port = 5432
    unix_socket_directories = '${socket}'
    unix_socket_group = 'forgejo'
    unix_socket_permissions = 0660
    password_encryption = 'scram-sha-256'
    logging_collector = off
  '';
  provision = pkgs.writeText "forgejo-database.sql" ''
    SELECT 'CREATE ROLE forgejo LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
      WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'forgejo') \gexec
    ALTER ROLE forgejo LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
    SELECT 'CREATE DATABASE forgejo OWNER forgejo'
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'forgejo') \gexec
    ALTER DATABASE forgejo OWNER TO forgejo;
    REVOKE ALL ON DATABASE forgejo FROM PUBLIC;
    GRANT CONNECT, TEMPORARY ON DATABASE forgejo TO forgejo;
    \connect forgejo
    REVOKE CREATE ON SCHEMA public FROM PUBLIC;
    ALTER SCHEMA public OWNER TO forgejo;
  '';
  beneathState = path: path == cfg.stateDir || lib.hasPrefix "${cfg.stateDir}/" path;
in
{
  imports = [ ../pki/maintenance.nix ];
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.user == "forgejo" && cfg.group == "forgejo";
        message = "Corporate Forgejo requires its dedicated forgejo user/group.";
      }
      {
        assertion =
          builtins.match "([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z]([a-z0-9-]*[a-z0-9])?" domain != null
          && builtins.stringLength domain <= 253
          && lib.all (label: builtins.stringLength label <= 63) (lib.splitString "." domain);
        message = "Forgejo server.DOMAIN must be a canonical lowercase DNS hostname, not an IP literal.";
      }
      {
        assertion = lib.all beneathState [
          cfg.customDir
          cfg.repositoryRoot
          cfg.lfs.contentDir
        ];
        message = "Forgejo custom, repository and LFS directories must remain inside stateDir for consistent backups/restores.";
      }
      {
        assertion = !cfg.useWizard && !cfg.dump.enable;
        message = "Corporate Forgejo uses declarative installation and encrypted corp-service-maintenance backups, not native unencrypted dump jobs.";
      }
      {
        assertion =
          cfg.database.type == "postgres"
          && !cfg.database.createDatabase
          && cfg.database.socket == socket
          && cfg.database.port == 5432
          && cfg.database.name == "forgejo"
          && cfg.database.user == "forgejo";
        message = "Forgejo must use only its dedicated PostgreSQL18 cluster and peer-authenticated application role.";
      }
    ];
    services.forgejo = {
      package = lib.mkDefault pkgs.forgejo;
      user = lib.mkDefault "forgejo";
      group = lib.mkDefault "forgejo";
      stateDir = lib.mkDefault "/var/lib/forgejo";
      database = {
        type = lib.mkDefault "postgres";
        createDatabase = false;
        socket = socket;
        port = 5432;
        name = "forgejo";
        user = "forgejo";
      };
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = lib.mkDefault "git.internal.htkrail.com";
          ROOT_URL = "https://${domain}/";
          PROTOCOL = "http";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = 9003;
          DISABLE_SSH = true;
          START_SSH_SERVER = false;
        };
        service = {
          DISABLE_REGISTRATION = true;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = false;
          SHOW_REGISTRATION_BUTTON = false;
        };
        security = {
          INSTALL_LOCK = true;
          REVERSE_PROXY_LIMIT = 1;
          REVERSE_PROXY_TRUSTED_PROXIES = "127.0.0.1/32,::1/128";
        };
        session = {
          COOKIE_SECURE = true;
          SAME_SITE = "lax";
        };
        migrations = {
          ALLOW_LOCALNETWORKS = false;
          SKIP_TLS_VERIFY = false;
        };
      };
    };
    users.users.postgres-forgejo = {
      isSystemUser = true;
      group = "forgejo";
      home = "/var/lib/postgresql-forgejo";
    };
    systemd.tmpfiles.rules = [ "d /var/lib/postgresql-forgejo 0700 postgres-forgejo forgejo - -" ];
    systemd.services.postgresql-forgejo = {
      description = "Dedicated PostgreSQL 18 cluster for Forgejo";
      wantedBy = [ "multi-user.target" ];
      before = [ "forgejo.service" ];
      serviceConfig = {
        Type = "notify";
        User = "postgres-forgejo";
        Group = "forgejo";
        RuntimeDirectory = "postgresql-forgejo";
        RuntimeDirectoryMode = "0750";
        UMask = "0077";
        ExecStart = "${pg}/bin/postgres -D ${pgData} -c config_file=${pgConfig}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        KillSignal = "SIGINT";
        TimeoutSec = 300;
        Restart = "on-failure";
        ProtectSystem = "strict";
        ReadWritePaths = [
          "/var/lib/postgresql-forgejo"
          socket
        ];
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
      };
      preStart = ''
        set -euo pipefail
        if [ ! -d ${pgData} ]; then
          ${pkgs.coreutils}/bin/mkdir -m 0700 ${pgData}
        fi
        if [ ! -f ${pgData}/PG_VERSION ]; then
          if [ -n "$(${pkgs.findutils}/bin/find ${pgData} -mindepth 1 -maxdepth 1 -print -quit)" ]; then
            echo 'Refusing initdb: nonempty PostgreSQL directory without PG_VERSION' >&2
            exit 1
          fi
          ${pg}/bin/initdb -D ${pgData} --username=forgejo-db-admin --auth-local=peer --auth-host=reject --encoding=UTF8 --locale=C.UTF-8
        fi
        if [ "$(<${pgData}/PG_VERSION)" != 18 ]; then
          echo 'Refusing to start: Forgejo cluster requires PostgreSQL major version 18; perform an explicit migration' >&2
          exit 1
        fi
      '';
      postStart = ''
        set -euo pipefail
        ${pg}/bin/psql --no-psqlrc --no-password -h ${socket} -p 5432 -U forgejo-db-admin -d postgres -v ON_ERROR_STOP=1 -f ${provision}
      '';
    };
    systemd.services.forgejo = {
      # Native module adds postgresql.target even with createDatabase=false.
      # Replace that dependency, retaining its secret bootstrap dependency.
      after = lib.mkForce [
        "network.target"
        "postgresql-forgejo.service"
        "forgejo-secrets.service"
      ];
      requires = [ "postgresql-forgejo.service" ];
      serviceConfig.PrivateUsers = true;
    };
    services.caddy.virtualHosts.${domain}.extraConfig = lib.mkIf config.services.caddy.enable ''
      ${lib.optionalString config.services.pki.enable "import corp_pki_tls"}
      reverse_proxy 127.0.0.1:9003
    '';
    services.corpServiceMaintenance.forgejo = {
      enable = true;
      inherit domain;
      stateDir = cfg.stateDir;
      customDir = cfg.customDir;
      package = cfg.package;
      externalSecrets = lib.filter (path: !(beneathState path)) (
        lib.flatten (lib.mapAttrsToList (_: values: lib.attrValues values) cfg.secrets)
      );
    };
  };
}
