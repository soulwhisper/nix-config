{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.gatus;

  alertCritical = {
    type = "pushover";
    enabled = true;
    failure-threshold = 3;
    success-threshold = 2;
    send-on-resolved = true;
    description = "🚨 **CRITICAL**: service [ENDPOINT_NAME] is down!";
    provider-override = {
      priority = 1;
      sound = "siren";
    };
  };

  alertWarning = {
    type = "pushover";
    enabled = true;
    failure-threshold = 5;
    send-on-resolved = false;
    description = "⚠️ **Warning**: [ENDPOINT_NAME] is unstable.";
    provider-override = {
      priority = 0;
      sound = "gamelan";
    };
  };
in {
  options.modules.services.gatus = {
    enable = lib.mkEnableOption "gatus";
    pushover.authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    endpoints.infra.dns = lib.mkOption {
      type = lib.types.str;
      default = "10.10.0.254";
      description = "DNS server used for internal infrastructure checks.";
    };
    endpoints.infra.httpProxy = lib.mkOption {
      type = lib.types.str;
      default = "http://10.10.0.254:1080";
      description = "HTTP Proxy used for internal infrastructure checks.";
    };
    endpoints.k8s.domain = lib.mkOption {
      type = lib.types.str;
      default = "noirprime.com";
      description = "Kubernetes cluster domain.";
    };
    endpoints.k8s.internal.ingress = lib.mkOption {
      type = lib.types.str;
      default = "10.10.0.131";
      description = "Kubernetes internal ingress IP address.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9400];

    systemd.services.gatus.serviceConfig.DynamicUser = lib.mkForce false;
    systemd.services.gatus.serviceConfig.EnvironmentFile = ["${cfg.pushover.authFile}"];
    systemd.services.gatus.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.gatus.serviceConfig.Group = lib.mkForce "appuser";

    services.gatus = {
      enable = true;
      openFirewall = false;
      settings = {
        web.port = 9400;
        alerting.pushover = {
          application-token = "\${PUSHOVER_TOKEN}";
          user-key = "\${PUSHOVER_KEY}";
        };
        endpoints = [
          # ---------------------------------------------------------
          # Infrastructure / Core
          # ---------------------------------------------------------
          {
            name = "Check: External-DNS (AdGuard)";
            group = "Infrastructure";
            url = "${cfg.endpoints.infra.dns}";
            dns = {
              query-name = "gateway-int.${cfg.endpoints.k8s.domain}";
              query-type = "A";
            };
            conditions = ["[BODY] == ${cfg.endpoints.k8s.internal.ingress}"];
            interval = "1m";
            alerts = [alertCritical];
          }
          {
            name = "Check: External-DNS (Cloudflare)";
            group = "Infrastructure";
            url = "223.5.5.5";
            dns = {
              query-name = "gateway-ext.${cfg.endpoints.k8s.domain}";
              query-type = "A";
            };
            conditions = ["[DNS_RCODE] == NOERROR"];
            interval = "1m";
            alerts = [alertCritical];
          }
          {
            name = "Check: TProxy";
            group = "Infrastructure";
            url = "https://www.google.com";
            client = {
              proxy = "${cfg.endpoints.infra.httpProxy}";
              headers = {
                "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";
              };
            };
            conditions = ["[STATUS] == 200"];
            interval = "1m";
            alerts = [alertCritical];
          }
          # ---------------------------------------------------------
          # Infrastructure / Services
          # ---------------------------------------------------------
          {
            name = "Infra: Postgres";
            group = "Infrastructure";
            url = "tcp://postgres.${cfg.endpoints.k8s.domain}";
            conditions = ["[CONNECTED] == true"];
            interval = "1m";
            alerts = [alertWarning];
          }
          # ---------------------------------------------------------
          # Connectivity / Apps
          # ---------------------------------------------------------
          {
            name = "App: Certificates";
            group = "Connectivity";
            url = "https://grafana.${cfg.endpoints.k8s.domain}";
            conditions = ["[CERTIFICATE_EXPIRATION] > 72h"];
            interval = "24h";
            alerts = [
              (alertWarning
                // {
                  failure-threshold = 1;
                  description = "📅 SSL Certificates for ${cfg.endpoints.k8s.domain} expire soon!";
                })
            ];
          }
          {
            name = "App: Internal (via AdGuard)";
            group = "Connectivity";
            url = "https://grafana.${cfg.endpoints.k8s.domain}";
            client = {
              dns-resolver = "tcp://${cfg.endpoints.infra.dns}:53";
              insecure = true;
            };
            conditions = ["[STATUS] == 200"];
            interval = "1m";
            alerts = [alertWarning];
          }
          {
            name = "App: External (via CF Tunnel)";
            group = "Connectivity";
            url = "https://kromgo.${cfg.endpoints.k8s.domain}";
            conditions = ["[STATUS] == 404"];
            interval = "1m";
            alerts = [alertWarning];
          }
        ];
      };
    };
  };
}
