{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.powerdns;
in {
  options.modules.services.powerdns = {
    enable = lib.mkEnableOption "powerdns";
    threads = {
      backend = lib.mkOption {
        type = lib.types.str;
        default = "1";
        description = "Backend threads, sqlite=1, pgsql/mysql = 4.";
      };
      receiver = lib.mkOption {
        type = lib.types.str;
        default = "4";
        description = "Listener threads, equal to CPU cores.";
      };
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "set webserver-allow-from and api-key";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    # use pure ip:port in case network failing
    networking.firewall.allowedTCPPorts = [53 9202 9203];
    networking.firewall.allowedUDPPorts = [53];

    # socket-auth dont need password
    services.mysql = {
      enable = true;
      dataDir = "/var/lib/mysql";
      package = pkgs.mysql84;
      ensureUsers = [
        {
          name = "powerdns";
          ensurePermissions = {
            "powerdns.*" = "ALL PRIVILEGES";
          };
        }
      ];
      initialDatabases = [
        {
          name = "powerdns";
          schema = "${pkgs.unstable.pdns}/share/doc/pdns/schema.mysql.sql";
        }
      ];
    };

    services.powerdns = {
      enable = true;
      secretFile = authFile;
      extraConfig = ''
        launch=gmysql
        gmysql-socket=/run/mysqld/mysqld.sock
        gmysql-dbname=powerdns
        gmysql-user=powerdns
        webserver=yes
        webserver-address=0.0.0.0
        webserver-port=9203
        webserver-allow-from=0.0.0.0/0
        api=yes
        api-key=powerdns
        enable-lua-records=true
        security-poll-suffix=
        version-string=anonymous
        max-tcp-connections=512
        receiver-threads=${cfg.threads.receiver}
        distributor-threads=${cfg.threads.backend}
        reuseport=yes
        cache-ttl=60
      '';
    };

    # poweradmin: 'php -S 0.0.0.0:80 -t poweradmin/'
    # POWERADMIN_SKIP_INSTALL='rm -rf poweradmin/install'

  };
}
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.powerdns;
in {
  options.modules.services.powerdns = {
    enable = lib.mkEnableOption "powerdns";
    threads = {
      backend = lib.mkOption {
        type = lib.types.str;
        default = "1";
        description = "Backend threads, sqlite=1, pgsql/mysql = 4.";
      };
      receiver = lib.mkOption {
        type = lib.types.str;
        default = "4";
        description = "Listener threads, equal to CPU cores.";
      };
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "set webserver-allow-from and api-key";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    # use pure ip:port in case network failing
    networking.firewall.allowedTCPPorts = [53 9202 9203];
    networking.firewall.allowedUDPPorts = [53];

    # socket-auth dont need password
    services.mysql = {
      enable = true;
      dataDir = "/var/lib/mysql";
      package = pkgs.mysql84;
      ensureUsers = [
        {
          name = "powerdns";
          ensurePermissions = {
            "powerdns.*" = "ALL PRIVILEGES";
          };
        }
      ];
      initialDatabases = [
        {
          name = "powerdns";
          schema = "${pkgs.unstable.pdns}/share/doc/pdns/schema.mysql.sql";
        }
      ];
    };

    services.powerdns = {
      enable = true;
      secretFile = authFile;
      extraConfig = ''
        launch=gmysql
        gmysql-socket=/run/mysqld/mysqld.sock
        gmysql-dbname=powerdns
        gmysql-user=powerdns
        webserver=yes
        webserver-address=0.0.0.0
        webserver-port=9203
        webserver-allow-from=0.0.0.0/0
        api=yes
        api-key=powerdns
        enable-lua-records=true
        security-poll-suffix=
        version-string=anonymous
        max-tcp-connections=512
        receiver-threads=${cfg.threads.receiver}
        distributor-threads=${cfg.threads.backend}
        reuseport=yes
        cache-ttl=60
      '';
    };

    # poweradmin: 'php -S 0.0.0.0:80 -t poweradmin/'
    # POWERADMIN_SKIP_INSTALL='rm -rf poweradmin/install'
  };
}
