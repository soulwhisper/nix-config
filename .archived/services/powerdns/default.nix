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

  # this service act as internal authoritative server
  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    # use pure ip:port in case network failing
    networking.firewall.allowedTCPPorts = [5301 9203 9204];
    networking.firewall.allowedUDPPorts = [5301];

    # socket-auth dont need password, use `pdns` user
    services.mysql = {
      enable = true;
      dataDir = "/var/lib/mysql";
      package = pkgs.mariadb;
      ensureUsers = [
        {
          name = "pdns";
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
      secretFile = cfg.authFile;
      extraConfig = ''
        local-port=5301
        launch=gmysql
        gmysql-host=localhost
        gmysql-dbname=powerdns
        gmysql-user=pdns
        webserver=yes
        webserver-address=0.0.0.0
        webserver-port=9204
        webserver-allow-from=127.0.0.1
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

    # create password-auth user `poweradmin`
    systemd.services.mysql.postStart = lib.mkAfter ''
      ( echo "USE mysql;"
        echo "CREATE USER IF NOT EXISTS 'poweradmin'@'localhost' IDENTIFIED WITH mysql_native_password;"
        echo "SET PASSWORD FOR 'poweradmin'@'localhost' = PASSWORD('poweradmin');"
        echo "GRANT ALL PRIVILEGES ON powerdns.* TO 'poweradmin'@'localhost';"
      ) | ${pkgs.mariadb}/bin/mysql -u mysql -N
    '';

    # `/var/lib/poweradmin/inc/config.inc.php` must be created manually
    # then delete `/var/lib/poweradmin/install`

    systemd.services.poweradmin = {
      description = "A web-based control panel for PowerDNS.";
      wants = ["network-online.target"];
      after = ["network-online.target" "powerdns.service"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      preStart = ''
        cp -r ${pkgs.poweradmin}/app/. /var/lib/poweradmin/
        if [ ! -f /var/lib/poweradmin/inc/config.inc.php ]; then
          cp -r ${pkgs.poweradmin}/install /var/lib/poweradmin/install
        fi
      '';
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.php}/bin/php -S 0.0.0.0:9203 -t /var/lib/poweradmin";
        StateDirectory = "poweradmin";
        RuntimeDirectory = "poweradmin";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
