{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.isc;
  # ref:https://github.com/11notes/docker-bind
  bindConfig = pkgs.writeTextFile {
    name = "named.conf";
    text = ''
      include "/var/lib/bind/rndc.key";
      include "/var/lib/bind/isc.key";
      include "/var/lib/bind/external.key";

      acl "trusted_networks" {
        127.0.0.1;
        10.0.0.0/8;
        172.16.0.0/12;
        192.168.0.0/16;
      };

      tls upstream-dot { remote-hostname "dns.alidns.com"; };

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
        minimal-responses yes;

        allow-query { any; };
        allow-query-cache { "trusted_networks"; };
        allow-recursion { "trusted_networks"; };
        dnssec-validation auto;

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

        zone "." IN { type hint; file "/var/lib/bind/root.db"; };
      };

      controls {
        inet 127.0.0.1 port 953 allow { 127.0.0.1; } keys { "rndc-key"; };
      };
      statistics-channels {
        inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
      };
    '';
  };
  externalKeyTemplate = pkgs.writeTextFile {
    name = "external.key.template";
    text = ''
      key "external-key" {
        algorithm hmac-sha256;
        secret "EXTERNAL_SECRET";
      };
    '';
  };
  catalogDBTemplate = pkgs.writeTextFile {
    name = "catalog.db";
    # UID=$(echo "${domain}" | sha1sum | tr -d "[:space:]-")
    text = ''
      $TTL 1h
      catalog.home.arpa. IN SOA . . 1 28800 7200 604800 86400
      catalog.home.arpa. IN NS invalid.
      version.catalog.home.arpa. IN TXT "1"
      035681e23f44e3da2d19fb7f6669e12e02ebe1ae.zones.catalog.home.arpa 3600 IN PTR homelab.internal
      64777a0872809c82546879498c944112624fe673.zones.catalog.home.arpa 3600 IN PTR noirprime.com
    '';
  };
  homeDBTemplate = pkgs.writeTextFile {
    name = "homelab.internal.db";
    text = ''
      homelab.internal. IN SOA . . 1 28800 7200 604800 86400
      homelab.internal. INS NS ns1.homelab.internal.
      ns1.homelab.internal. IN A 127.0.0.1
    '';
  };
  domainDBTemplate = pkgs.writeTextFile {
    name = "noirprime.com.db";
    text = ''
      noirprime.com. IN SOA . . 1 28800 7200 604800 86400
      noirprime.com. INS NS ns1.noirprime.com.
      ns1.noirprime.com. IN A 127.0.0.1
    '';
  };
in {
  options.modules.services.isc = {
    enable = lib.mkEnableOption "isc-stack";
    bind.authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
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
      "C /var/lib/bind/external.key.template 0755 appuser appuser - ${externalKeyTemplate}"
      "C /var/lib/bind/catalog.db 0755 appuser appuser - ${catalogDBTemplate}"
      "C /var/lib/bind/homelab.internal.db 0755 appuser appuser - ${homeDBTemplate}"
      "C /var/lib/bind/noirprime.com.db 0755 appuser appuser - ${domainDBTemplate}"
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
          ${pkgs.bind}/bin/rndc-confgen -a -c /var/lib/bind/isc.key -k isc-key
        fi
        if [ ! -f /var/lib/bind/external.key ]; then
          sed "s|EXTERNAL_SECRET|$(cat ${cfg.bind.authFile}| tr -d '\n')|" /var/lib/bind/external.key.template > /var/lib/bind/external.key
        fi

        # Bootstrap root hints. We cannot resolve "a.root-servers.net" before a
        # resolver exists, so on first run query its hard-coded IP (198.41.0.4),
        # exactly like the 11notes rootdb script. Refresh by hostname afterwards.
        if [ ! -f /var/lib/bind/root.db ]; then
          ROOT_NS=198.41.0.4
        else
          ROOT_NS=a.root-servers.net
        fi
        ${pkgs.bind}/bin/mdig +bufsize=1200 +norec NS . @"$ROOT_NS" \
          | egrep -v ';|^$' | egrep -v '\S.+AAAA.+|^$' | sort \
          > /var/lib/bind/root.db.new \
          && mv /var/lib/bind/root.db.new /var/lib/bind/root.db
      '';
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
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
