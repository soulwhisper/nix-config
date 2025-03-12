{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.powerdns;
  hashKeyFile = pkgs.writeTextFile {
    name = "pdns-hash";
    text = builtins.substring 0 50 (builtins.hashString "sha256" "powerdns");
  };
in {
  options.modules.services.powerdns = {
    enable = lib.mkEnableOption "powerdns";
    api.subnets = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };
    api.port = lib.mkOption {
      type = lib.types.str;
      default = "9202";
    };
    api.key = lib.mkOption {
      type = lib.types.str;
      default = "powerdns";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    networking.firewall.allowedTCPPorts = [53 9201 9202];
    networking.firewall.allowedUDPPorts = [53];

    environment.etc."pdns/pdns.conf" = {
      mode = "0600";
      source = pkgs.writeText "pdns/pdns.conf" ''
        launch=gsqlite3
        gsqlite3-database=/etc/pdns/pdns.sqlite3
        gsqlite3-dnssec=false
        webserver=yes
        webserver-address=0.0.0.0
        webserver-port=${cfg.api.port}
        webserver-allow-from=${cfg.api.subnets}
        api=yes
        api-key=${cfg.api.key}
        enable-lua-records=true
        security-poll-suffix=
        version-string=anonymous
      '';
    };

    systemd.services.powerdns = {
      description = "powerdns Home: Network-level blocker";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      unitConfig = {
        StartLimitIntervalSec = 5;
        StartLimitBurst = 10;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStartPre = pkgs.writeShellScript "pdns-pre-start" ''
          test -f "/etc/pdns/pdns.sqlite3" || ${pkgs.sqlite}/bin/sqlite3 /etc/pdns/pdns.sqlite3 < ${pkgs.pdns}/share/doc/pdns/schema.sqlite3.sql
        '';
        ExecStart = "${pkgs.pdns}/bin/pdns_server --config-dir=/etc/pdns --guardian=no --daemon=no --disable-syslog --log-timestamp=no --write-pid=no";
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE" "CAP_NET_RAW"];
        Restart = "always";
        RestartSec = 10;
      };
    };

    services.powerdns-admin = {
      enable = true;
      secretKeyFile = hashKeyFile;
      saltFile = hashKeyFile;
      config = ''
        BIND_ADDRESS = '0.0.0.0'
        PORT = 9201
        SQLALCHEMY_DATABASE_URI = 'sqlite:////etc/pdns/pdns.sqlite3'
      '';
    };
  };
}
