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
    api = {
      subnets = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 9203;
      };
      key = lib.mkOption {
        type = lib.types.str;
        default = "powerdns";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    # use pure ip:port in case network failing
    networking.firewall.allowedTCPPorts = [5301 9202 cfg.api.port];
    networking.firewall.allowedUDPPorts = [5301];

    systemd.tmpfiles.rules = [
      "d /var/lib/powerdns 0755 pdns pdns - -"
    ];

    services.powerdns = {
      enable = true;
      extraConfig = ''
        launch=gsqlite3
        gsqlite3-database=/var/lib/powerdns/pdns.sqlite3
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
    services.powerdns-admin = {
      enable = true;
      config = ''
        BIND_ADDRESS = '0.0.0.0'
        PORT = 9202
        SQLALCHEMY_DATABASE_URI = 'sqlite:////var/lib/powerdns/pdns.sqlite3'
      '';
    };
  };
}
