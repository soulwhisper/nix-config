{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.services.forgejo;
  reverseProxyCaddy = config.modules.services.caddy;
  metricsTokenFile = "${cfg.stateDir}/metrics_token";
  runnerTokenFile = "${cfg.stateDir}/runner_token";
in
{
  options.modules.services.forgejo = {
    enable = lib.mkEnableOption "Forgejo with a trusted host runner";
    package = lib.mkPackageOption pkgs "forgejo" { };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "git.noirprime.com";
      description = "Internal DNS name used for HTTPS and SSH clone URLs.";
    };
    rootUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://${cfg.domain}/";
      defaultText = lib.literalExpression ''"https://''${config.modules.services.forgejo.domain}/"'';
      description = "Externally visible Forgejo base URL.";
    };
    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/forgejo";
    };
    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 9003;
    };
    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 9004;
    };
    runner = {
      enable = lib.mkEnableOption "a capacity-one trusted host runner";
      url = lib.mkOption {
        type = lib.types.str;
        default = cfg.rootUrl;
        defaultText = lib.literalExpression "config.modules.services.forgejo.rootUrl";
        description = "Forgejo URL reachable by the runner.";
      };
      capacity = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1;
      };
      timeout = lib.mkOption {
        type = lib.types.str;
        default = "1h";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      cfg.sshPort
    ]
    ++ lib.optional (!reverseProxyCaddy.enable) cfg.httpPort;

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy 127.0.0.1:${toString cfg.httpPort}
      }
    '';

    environment.systemPackages = [
      cfg.package
      pkgs.forgejo-cli
    ];

    services.forgejo = {
      enable = true;
      package = cfg.package;
      stateDir = cfg.stateDir;
      database.type = "sqlite3";
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = cfg.rootUrl;
          HTTP_ADDR = if reverseProxyCaddy.enable then "127.0.0.1" else "0.0.0.0";
          HTTP_PORT = cfg.httpPort;
          SSH_DOMAIN = cfg.domain;
          SSH_PORT = cfg.sshPort;
          SSH_LISTEN_PORT = cfg.sshPort;
          START_SSH_SERVER = true;
        };
        security.INSTALL_LOCK = true;
        session.COOKIE_SECURE = lib.hasPrefix "https://" cfg.rootUrl;
        service = {
          DISABLE_REGISTRATION = true;
          REQUIRE_SIGNIN_VIEW = true;
          DEFAULT_USER_VISIBILITY = "private";
          DEFAULT_KEEP_EMAIL_PRIVATE = true;
        };
        repository = {
          DEFAULT_PRIVATE = "private";
          DEFAULT_PUSH_CREATE_PRIVATE = true;
        };
        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "https://data.forgejo.org";
          LOG_RETENTION_DAYS = 30;
          ARTIFACT_RETENTION_DAYS = 30;
        };
        metrics.ENABLED = true;
        log = {
          MODE = "file";
          ROOT_PATH = "${cfg.stateDir}/log";
          LEVEL = "Info";
        };
        migrations.ALLOW_LOCALNETWORKS = false;
        proxy = {
          PROXY_ENABLED = "true";
          PROXY_URL = "http://127.0.0.1:1080";
          PROXY_HOSTS = "*.github.com,github.com,raw.githubusercontent.com";
        };
      };
      secrets.metrics.TOKEN = metricsTokenFile;
    };

    # Keep generated credentials out of the Nix store and SOPS. They live in
    # Forgejo's state directory and are covered by the cold Restic backup.
    systemd.services.forgejo-metrics-token = {
      description = "Create the Forgejo metrics credential once";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "forgejo";
        Group = "forgejo";
        StateDirectory = "forgejo";
        ExecStart = pkgs.writeShellScript "forgejo-metrics-token" ''
          set -euo pipefail
          if [ ! -s ${metricsTokenFile} ]; then
            umask 077
            ${lib.getExe pkgs.openssl} rand -hex 32 > ${metricsTokenFile}
          fi
        '';
      };
    };

    systemd.services.forgejo-secrets = {
      after = [ "forgejo-metrics-token.service" ];
      requires = [ "forgejo-metrics-token.service" ];
    };

    systemd.services.forgejo-runner-registration = lib.mkIf cfg.runner.enable {
      description = "Create the Forgejo runner registration credential once";
      after = [ "forgejo.service" ];
      requires = [ "forgejo.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        HOME = cfg.stateDir;
        GITEA_WORK_DIR = cfg.stateDir;
        FORGEJO_WORK_DIR = cfg.stateDir;
        FORGEJO_CUSTOM = "${cfg.stateDir}/custom";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "forgejo";
        Group = "forgejo";
        StateDirectory = "forgejo";
        ExecStart = pkgs.writeShellScript "forgejo-runner-registration" ''
          set -euo pipefail
          if [ ! -s ${runnerTokenFile} ]; then
            umask 077
            token="$(${lib.getExe cfg.package} actions generate-runner-token)"
            printf 'TOKEN=%s\n' "$token" > ${runnerTokenFile}
          fi
        '';
      };
    };

    services.gitea-actions-runner = lib.mkIf cfg.runner.enable {
      package = pkgs.forgejo-runner;
      instances.main = {
        enable = true;
        name = config.networking.hostName;
        url = cfg.runner.url;
        tokenFile = runnerTokenFile;
        labels = [ "nix:host" ];
        settings = {
          runner = {
            capacity = cfg.runner.capacity;
            timeout = cfg.runner.timeout;
          };
          cache.enabled = true;
        };
        hostPackages = with pkgs; [
          bash
          coreutils
          curl
          gawk
          git
          git-lfs
          gnused
          jq
          nodejs
          wget
          config.nix.package
          nixfmt
        ];
      };
    };

    systemd.services.gitea-runner-main = lib.mkIf cfg.runner.enable {
      after = [ "forgejo-runner-registration.service" ];
      requires = [ "forgejo-runner-registration.service" ];
      serviceConfig = {
        CPUQuota = "200%";
        MemoryMax = "5G";
        TasksMax = 512;
      };
    };
  };
}
