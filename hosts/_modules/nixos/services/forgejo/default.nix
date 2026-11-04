{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo;
  pg = pkgs.postgresql_18;
  forgejo = pkgs.corp-forgejo;
  pgData = "/var/lib/postgresql-forgejo/18";
  socket = "/run/postgresql-forgejo";
  hba = pkgs.writeText "forgejo-pg_hba.conf" ''
    local forgejo forgejo peer map=forgejo-app
    local all forgejo-db-admin peer map=forgejo-admin
    local all all reject
  '';
  ident = pkgs.writeText "forgejo-pg_ident.conf" ''
    forgejo-app appuser forgejo
    forgejo-admin root forgejo-db-admin
  '';
  pgConfig = (pkgs.formats.keyValue { }).generate "forgejo-postgresql.conf" {
    data_directory = "'${pgData}'";
    hba_file = "'${hba}'";
    ident_file = "'${ident}'";
    listen_addresses = "''";
    port = 5432;
    unix_socket_directories = "'${socket}'";
    unix_socket_permissions = "0700";
    password_encryption = "'scram-sha-256'";
    logging_collector = "off";
  };
  provision = pkgs.writeText "forgejo-database.sql" ''
    SELECT 'CREATE ROLE forgejo LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS'
      WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'forgejo') \gexec
    ALTER ROLE forgejo LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD NULL;
    SELECT 'CREATE DATABASE forgejo OWNER forgejo'
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'forgejo') \gexec
    ALTER DATABASE forgejo OWNER TO forgejo;
    REVOKE ALL ON DATABASE forgejo FROM PUBLIC;
    GRANT CONNECT, TEMPORARY ON DATABASE forgejo TO forgejo;
    \connect forgejo
    REVOKE CREATE ON SCHEMA public FROM PUBLIC;
    ALTER SCHEMA public OWNER TO forgejo;
  '';
  appConfig = (pkgs.formats.ini { }).generate "forgejo-app.ini" {
    DEFAULT = {
      RUN_MODE = "prod";
      RUN_USER = "appuser";
      WORK_PATH = "/var/lib/forgejo";
    };
    database = {
      DB_TYPE = "postgres";
      HOST = "${socket}:5432";
      NAME = "forgejo";
      USER = "forgejo";
      SSL_MODE = "disable";
    };
    repository.ROOT = "/var/lib/forgejo/repositories";
    server = {
      DOMAIN = cfg.domain;
      ROOT_URL = "https://${cfg.domain}/";
      PROTOCOL = "http";
      HTTP_ADDR = "127.0.0.1";
      HTTP_PORT = 9003;
      DISABLE_SSH = true;
      START_SSH_SERVER = false;
      APP_DATA_PATH = "/var/lib/forgejo/data";
      STATIC_ROOT_PATH = "${forgejo.data}";
      LFS_START_SERVER = true;
    };
    lfs.PATH = "/var/lib/forgejo/data/lfs";
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
      PROVIDER = "file";
      PROVIDER_CONFIG = "/var/lib/forgejo/data/sessions";
    };
    migrations = {
      ALLOW_LOCALNETWORKS = false;
      SKIP_TLS_VERIFY = false;
    };
    log = {
      MODE = "console";
      ROOT_PATH = "/var/lib/forgejo/log";
    };
  };
in
{
  disabledModules = [ "services/misc/forgejo.nix" ];
  imports = [ ../pki/maintenance.nix ];
  meta.doc = ./forgejo.md;

  options.services.forgejo = {
    enable = lib.mkEnableOption "the corporate Forgejo service";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "git.internal.htkrail.com";
      description = "DNS hostname used by Forgejo and its Caddy virtual host.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ forgejo ];
    systemd.tmpfiles.rules = [
      "d /var/lib/forgejo 0700 appuser appuser - -"
      "d /var/lib/forgejo/custom 0700 appuser appuser - -"
      "d /var/lib/forgejo/custom/conf 0700 appuser appuser - -"
      "d /var/lib/forgejo/repositories 0700 appuser appuser - -"
      "d /var/lib/forgejo/data 0700 appuser appuser - -"
      "d /var/lib/forgejo/data/lfs 0700 appuser appuser - -"
      "d /var/lib/postgresql-forgejo 0700 appuser appuser - -"
    ];

    systemd.services.postgresql-forgejo = {
      description = "Private PostgreSQL 18 cluster for Forgejo";
      wantedBy = [ "multi-user.target" ];
      before = [ "forgejo.service" ];
      serviceConfig = {
        Type = "notify";
        User = "appuser";
        Group = "appuser";
        RuntimeDirectory = "postgresql-forgejo";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecStart = "${pg}/bin/postgres -D ${pgData} -c config_file=${pgConfig}";
        # Provisioning connects through the root-only peer map, never appuser.
        ExecStartPost = "+${pg}/bin/psql --no-psqlrc --no-password -h ${socket} -p 5432 -U forgejo-db-admin -d postgres -v ON_ERROR_STOP=1 -f ${provision}";
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
    };

    systemd.services.forgejo = {
      description = "Forgejo corporate software forge";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql-forgejo.service"
      ];
      requires = [ "postgresql-forgejo.service" ];
      environment = {
        USER = "appuser";
        HOME = "/var/lib/forgejo";
        FORGEJO__security__SECRET_KEY__FILE = "/var/lib/forgejo/custom/conf/secret_key";
        FORGEJO__security__INTERNAL_TOKEN__FILE = "/var/lib/forgejo/custom/conf/internal_token";
        FORGEJO__oauth2__JWT_SECRET__FILE = "/var/lib/forgejo/custom/conf/oauth2_jwt_secret";
        FORGEJO__server__LFS_JWT_SECRET__FILE = "/var/lib/forgejo/custom/conf/lfs_jwt_secret";
      };
      preStart = ''
        set -euo pipefail
        umask 077
        ensureSecret() {
          if [ ! -s "$2" ]; then
            ${lib.getExe forgejo} generate secret "$1" > "$2"
          fi
        }
        ensureSecret SECRET_KEY /var/lib/forgejo/custom/conf/secret_key
        ensureSecret INTERNAL_TOKEN /var/lib/forgejo/custom/conf/internal_token
        ensureSecret JWT_SECRET /var/lib/forgejo/custom/conf/oauth2_jwt_secret
        ensureSecret JWT_SECRET /var/lib/forgejo/custom/conf/lfs_jwt_secret
        ${pkgs.coreutils}/bin/install -m 0600 ${appConfig} /var/lib/forgejo/custom/conf/app.ini
        ${forgejo}/bin/environment-to-ini --work-path=/var/lib/forgejo --custom-path=/var/lib/forgejo/custom --config=/var/lib/forgejo/custom/conf/app.ini
        ${lib.getExe forgejo} migrate
        ${lib.getExe forgejo} admin regenerate hooks
      '';
      serviceConfig = {
        Type = "notify";
        User = "appuser";
        Group = "appuser";
        WorkingDirectory = "/var/lib/forgejo";
        ExecStart = "${lib.getExe forgejo} web";
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStartSec = 300;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/var/lib/forgejo" ];
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
      };
    };

    services.caddy.virtualHosts.${cfg.domain}.extraConfig = lib.mkIf config.services.caddy.enable ''
      ${lib.optionalString config.services.pki.enable "import corp_pki_tls"}
      reverse_proxy 127.0.0.1:9003
    '';
  };
}
