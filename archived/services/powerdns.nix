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
    api.subnets = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };
    api.port = lib.mkOption {
      type = lib.types.port;
      default = 9202;
    };
    api.key = lib.mkOption {
      type = lib.types.str;
      default = "powerdns";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    # use pure ip:port in case network failing
    networking.firewall.allowedTCPPorts = [53 9201 cfg.api.port];
    networking.firewall.allowedUDPPorts = [53];

    environment.etc."pdns/pdns.conf" = {
      mode = "0600";
      source = pkgs.writeText "pdns/pdns.conf" ''
        launch=gsqlite3
        gsqlite3-database=/etc/pdns/pdns.sqlite3
        gsqlite3-dnssec=false
        webserver=yes
        webserver-address=0.0.0.0
        webserver-port=${builtins.toString cfg.api.port}
        webserver-allow-from=${cfg.api.subnets}
        api=yes
        api-key=${cfg.api.key}
        enable-lua-records=true
        security-poll-suffix=
        version-string=anonymous
      '';
    };

    systemd.services.powerdns = {
      wants = ["network-online.target"];
      after = ["network-online.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "pdns-pre-start" ''
          mkdir -p /etc/pdns
          chmod 777 /etc/pdns
          test -f "/etc/pdns/pdns.sqlite3" || ${pkgs.sqlite}/bin/sqlite3 /etc/pdns/pdns.sqlite3 < ${pkgs.pdns}/share/doc/pdns/schema.sqlite3.sql
          chmod 666 /etc/pdns/pdns.sqlite3
        '';
        ExecStart = "${pkgs.pdns}/bin/pdns_server --config-dir=/etc/pdns --guardian=no --daemon=no --disable-syslog --log-timestamp=no --write-pid=no";
        Restart = "always";
        RestartSec = 10;
      };
    };

    # fix powerdns-admin packaging issue; deprecated reason: powerdns-admin/poweradmin has too many bugs with sqlite
    systemd.services.powerdns-admin = {
      description = "PowerDNS web interface";
      wantedBy = ["network-online.target"];
      after = ["powerdns.service"];
      serviceConfig = {
        ExecStart = "${pkgs.powerdns-admin}/bin/powerdns-admin --pid /run/powerdns-admin/pid";
        ExecStartPre = "${pkgs.coreutils}/bin/env FLASK_APP=${pkgs.powerdns-admin}/share/powerdnsadmin/__init__.py ${pkgs.python3Packages.flask}/bin/flask db upgrade -d ${pkgs.powerdns-admin}/share/migrations";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        ExecStop = "${pkgs.coreutils}/bin/kill -TERM $MAINPID";
        PIDFile = "/run/powerdns-admin/pid";
        RuntimeDirectory = "powerdns-admin";
      };
      environment.PYTHONPATH = pkgs.powerdns-admin.pythonPath;
      environment.FLASK_CONF = builtins.toFile "powerdns-admin-config.py" ''
        BIND_ADDRESS = '0.0.0.0'
        PORT = 9201
        SQLALCHEMY_DATABASE_URI = 'sqlite:////etc/pdns/pdns.sqlite3'
        SESSION_TYPE = 'filesystem'
        SESSION_FILE_DIR='/run/powerdns-admin/flask-sessions'
      '';
    };
  };
}
