{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.lobechat;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.lobechat = {
    enable = lib.mkEnableOption "lobechat";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/lobechat";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9804];

    services.caddy.virtualHosts."chat.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9804
      }
    '';
    # app
    modules.services.ollama.enable = true;
    modules.services.ollama.models = ["nomic-embed-text"];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root - -"
    ];

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."pgvector" = {
      autoStart = true;
      image = "pgvector/pgvector:pg17";
      extraOptions = ["--pull=newer"];
      ports = [
        "5433:5432/tcp"
      ];
      environment = {
        POSTGRES_DB = "lobechat";
        POSTGRES_USER = "lobechat";
        POSTGRES_PASSWORD = "lobechat";
      };
      volumes = [
        "${cfg.dataDir}:/var/lib/postgresql/data"
      ];
    };
    virtualisation.oci-containers.containers."lobechat" = {
      autoStart = true;
      image = "lobehub/lobe-chat-database";
      extraOptions = ["--pull=newer"];
      ports = [
        "9804:3210/tcp"
      ];
      environment = {
        APP_URL = "https://chat.noirprime.com";
        DATABASE_URL = "postgres://lobechat:lobechat@host.containers.internal:5433/lobechat";
        NEXTAUTH_URL = "https://chat.noirprime.com/api/auth";
        # knowledgebase, use ollama instead of openai
        OLLAMA_PROXY_URL = "http://host.containers.internal:9400";
        DEFAULT_FILES_CONFIG = "embedding_model=ollama/nomic-embed-text";
        # encryption salt, via `openssl rand -base64 32`
        NEXT_AUTH_SECRET = "uOl5uiCgy9x/H2atftZJY8z7XulbQMxbXjA+QNq2Fks=";
        KEY_VAULTS_SECRET = "gCNEJ044+M4Rj2TDPraaHcupvC3kqkaZMk44j6KzNJk=";
        # s3 storage
        S3_BUCKET = "lobechat";
        # auth
        NEXT_AUTH_SSO_PROVIDERS = "github";
      };
      environmentFiles = [
        "${cfg.authFile}"
      ];
    };
  };
}
