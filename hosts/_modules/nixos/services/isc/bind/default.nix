{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.isc;
  bindConfig = pkgs.writeTextFile {
    name = "named.conf";
    text = ''
      include "/var/lib/bind/rndc.key";
      include "/var/lib/bind/isc.key";
      include "${cfg.bind.externalKey}";

      acl "trusted_networks" {
        127.0.0.1;
        10.0.0.0/8;
        172.16.0.0/12;
        192.168.0.0/16;
      };

      options {
        directory "/var/lib/bind";
        pid-file "/run/named/named.pid";
        listen-on { any; };

        recursion yes;
        allow-new-zones yes;
        auth-nxdomain no;
        version "0.0";
        prefetch 2 9;
        recursive-clients 4096;

        allow-query { any; };
        allow-recursion { "trusted_networks"; };
        dnssec-validation auto;

        tls upstream-dot { remote-hostname "dns.alidns.com"; };
        forwarders port 853 tls upstream-dot { 223.5.5.5; 223.6.6.6; };
      };

      view "main" {
        match-clients { any; };

        zone "catalog.home.arpa" {
          type master;
          file "catalog.db";
          allow-update { key "isc-key"; };
        };

        zone "homelab.internal" {
          type master;
          file "homelab.internal.db";
          allow-update { key "isc-key"; };
        };

        zone "noirprime.com" {
          type master;
          file "noirprime.com.db";
          allow-update { key "external-key"; };
        };

        zone "." IN { type hint; file "${pkgs.bind}/etc/root.hints"; };
      };

      controls {
        inet 127.0.0.1 port 953 allow { 127.0.0.1; } keys { "rndc-key"; };
      };
      statistics-channels {
        inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
      };
    '';
  };
in {
  options.modules.services.isc = {
    enable = lib.mkEnableOption "isc-stack";
    bind.externalKey = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "rndc-confgen -a -c external.key -k external-key";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network.config.networkConfig.UseDomains = lib.mkDefault false;
    networking.resolvconf.useLocalResolver = lib.mkForce false;
    services.resolved.enable = lib.mkForce false;

    networking.firewall.allowedTCPPorts = [53];
    networking.firewall.allowedUDPPorts = [53];

    systemd.tmpfiles.rules = [
      "d /var/lib/bind 0755 appuser appuser - -"
      "C /var/lib/bind/named.conf 0755 appuser appuser - ${bindConfig}"
    ];

    systemd.services.bind = {
      description = "ISC-Stack BIND9 Service";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      preStart = ''
        if [ ! -f /var/lib/bind/rndc.key ]; then
          ${pkgs.bind}/bin/rndc-confgen -a -c /var/lib/bind/rndc.key -k rndc-key
        fi
        if [ ! -f /var/lib/bind/isc.key ]; then
          ${pkgs.bind}/bin/tsig-keygen -a -c /var/lib/bind/isc.key -k isc-key
        fi
      '';
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        StateDirectory = "bind";
        RuntimeDirectory = "named";
        RuntimeDirectoryPreserve = "yes";
        Type = "forking";
        Restart = "always";
        RestartSec = 5;
        ExecStart = "${pkgs.bind}/bin/named -c ${bindConfig}";
        ExecReload = "${pkgs.bind}/bin/rndc -k /var/lib/bind/rndc.key reload";
        ExecStop = "${pkgs.bind}/bin/rndc -k /var/lib/bind/rndc.key stop";
      };
    };
  };
}
