{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.services.dsh;
  caddy = config.modules.services.caddy;
in
{
  options.modules.services.dsh = {
    enable = lib.mkEnableOption "dsh-web";

    image = lib.mkOption {
      type = lib.types.str;
      # Published web-0.2.1-rc.2-r2; bump to web-0.2.2-alpha.2-r1 only after
      # its GHCR tag exists and the digest has been inspected.
      default = "ghcr.io/soulwhisper/dsh-web@sha256:64505485b1ed284dd90a8ec51ca57dda11542e8e6d56e0f12ba783008bdf2a3e";
      description = "dsh-web image, pinned by digest.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "dsh.noirprime.com";
      description = "Public HTTPS hostname served by Caddy.";
    };

    containerAddr = lib.mkOption {
      type = lib.types.str;
      default = "192.168.10.3";
      description = "Concrete container IP on the dsh Podman network.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3080;
      description = "dsh listener port inside the container.";
    };

    networkSubnet = lib.mkOption {
      type = lib.types.str;
      default = "192.168.10.0/24";
      description = "Podman network subnet used by dsh.";
    };

    networkGateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.10.1";
      description = "Podman network gateway; also the trusted Caddy peer.";
    };

    allowedSubjects = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "admin" ];
      description = "Stable forward-auth subjects allowed as the DSH owner.";
    };

    trustedProxyCidrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "192.168.10.1/32" ];
      description = "Concrete peer CIDRs allowed to inject the identity header.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = caddy.enable;
        message = "modules.services.dsh requires modules.services.caddy as the verified edge";
      }
    ];

    # DSH has no anonymous health or login path. It fails closed without a
    # verified edge, so this module deliberately publishes no host port.
    virtualisation.podman.defaultNetwork.settings = {
      dns_enabled = true;
      subnets = [
        {
          subnet = cfg.networkSubnet;
          gateway = cfg.networkGateway;
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/dsh/data 0700 soulwhisper soulwhisper - -"
      "d /var/lib/dsh/workspace 0700 soulwhisper soulwhisper - -"
      "d /var/lib/dsh/cache 0700 soulwhisper soulwhisper - -"
      "d /var/lib/dsh/logs 0700 soulwhisper soulwhisper - -"
      "d /var/lib/dsh/backups 0700 soulwhisper soulwhisper - -"
    ];

    systemd.services.podman-dsh-web.serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = 5;
    };

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."dsh-web" = {
      autoStart = true;
      image = cfg.image;
      user = "1000:1000";
      environment = {
        DSH_HOST = cfg.containerAddr;
        DSH_PORT = toString cfg.port;
        DSH_PUBLIC_URL = "https://${cfg.domain}";
        DSH_TRUSTED_HOSTS = cfg.domain;
        DSH_FORWARD_AUTH_HEADER = "x-authentik-uid";
        DSH_FORWARD_AUTH_ALLOWED_SUBJECTS = lib.concatStringsSep "," cfg.allowedSubjects;
        DSH_FORWARD_AUTH_TRUSTED_PROXY_CIDRS = lib.concatStringsSep "," cfg.trustedProxyCidrs;
        DSH_FORWARD_AUTH_MAX_CONNECTION_SECONDS = "900";
      };
      volumes = [
        "/var/lib/dsh/data:/data"
        "/var/lib/dsh/workspace:/workspace"
        "/var/lib/dsh/cache:/cache"
        "/var/lib/dsh/logs:/logs"
        "/var/lib/dsh/backups:/backups"
      ];
      extraOptions = [
        "--network=podman"
        "--ip=${cfg.containerAddr}"
        "--read-only"
        "--cap-drop=ALL"
        "--security-opt=no-new-privileges:true"
        "--pids-limit=512"
        "--tmpfs=/tmp:rw,nosuid,nodev,mode=1777,size=256m"
        # The host proxy env points at 127.0.0.1:1080; inside the container
        # that is the container itself. Keep direct egress unless a reachable
        # proxy is configured explicitly.
        "--http-proxy=false"
      ];
    };

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = ''
      basic_auth {
        admin {$DSH_BASIC_AUTH_HASH}
      }
      reverse_proxy ${cfg.containerAddr}:${toString cfg.port} {
        header_up Host {host}
        header_up X-Authentik-Uid {http.auth.user.id}
      }
    '';
  };
}
