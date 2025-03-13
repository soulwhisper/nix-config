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
        webserver-port=${toString cfg.api.port}
        webserver-allow-from=${cfg.api.subnets}
        api=yes
        api-key=${cfg.api.key}
        enable-lua-records=true
        security-poll-suffix=
        version-string=anonymous
      '';
    };
    environment.etc."pdns/config.inc.php" = {
      mode = "0666";
      source = ./config.inc.php;
    };

    systemd.services.powerdns = {
      wants = ["network-online.target"];
      after = ["network-online.target"];
      unitConfig = {
        StartLimitIntervalSec = 5;
        StartLimitBurst = 10;
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

    systemd.services.podman-poweradmin.after = ["powerdns.service"];
    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."poweradmin" = {
      autoStart = true;
      image = "lamgc/poweradmin:latest";
      ports = [
        "9201:80/tcp"
      ];
      environment = {
        POWERADMIN_SKIP_INSTALL = "true";
      };
      volumes = [
        "/etc/pdns/config.inc.php:/var/www/html/inc/config.inc.php"
        "/etc/pdns/pdns.sqlite3:/etc/pdns/pdns.sqlite3"
      ];
    };
  };
}
