{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.harbor;
  reverseProxyCaddy = config.modules.services.caddy;
  coreConfigFile = ./config/core.conf;
  coreKeyFile = ./config/private_key.pem;
  jobserviceConfigFile = ./config/jobservice.yml;
  registryConfigFile = ./config/registry.yml;
  registryctlConfigFile = ./config/registryctl.yml;
in {
  options.modules.services.harbor = {
    enable = lib.mkEnableOption "harbor";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/apps/harbor";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "harbor.noirprime.com";
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9804];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable (
      (lib.optionalString cfg.internal "tls internal\n")
      + ''
        handle_path /static/* {
          root * /var/lib/netbox/static
          encode gzip zstd
          file_server
        }
        handle {
          reverse_proxy localhost:9804
        }
      ''
    );

    # remap ports:
    # core:8080 ->
    # registry:5000
    # registryctl:8080
    # jobservice:8080
    # postgresql:5432 ->
    # redis:6379 ->

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
      "d ${cfg.dataDir}/core 0755 appuser appuser - -"
      "d ${cfg.dataDir}/config 0755 appuser appuser - -"
      "d ${cfg.dataDir}/config/core 0755 appuser appuser - -"
      "C+ ${cfg.dataDir}/config/core/app.conf 0700 appuser appuser - ${coreConfigFile}"
      "C+ ${cfg.dataDir}/config/core/private_key.pem 0700 appuser appuser - ${coreKeyFile}"
      "d ${cfg.dataDir}/config/jobservice 0755 appuser appuser - -"
      "C+ ${cfg.dataDir}/config/jobservice/config.yml 0700 appuser appuser - ${jobserviceConfigFile}"
      "d ${cfg.dataDir}/config/registry 0755 appuser appuser - -"
      "C+ ${cfg.dataDir}/config/registry/config.yml 0700 appuser appuser - ${registryConfigFile}"
      "d ${cfg.dataDir}/config/registryctl 0755 appuser appuser - -"
      "C+ ${cfg.dataDir}/config/registryctl/config.yml 0700 appuser appuser - ${registryctlConfigFile}"
      "d ${cfg.dataDir}/postgresql 0755 appuser appuser - -"
      "d ${cfg.dataDir}/registry 0755 appuser appuser - -"
      "d ${cfg.dataDir}/scanner/trivy 0755 appuser appuser - -"
      "d ${cfg.dataDir}/scanner/reports 0755 appuser appuser - -"
    ];

    modules.services.podman.enable = true;
    virtualisation.oci-containers.containers."harbor-registry" = {
      autoStart = true;
      image = "docker.io/bitnami/harbor-registry:2";
      extraOptions = ["--pull=newer"];
      environment = {
        REGISTRY_HTTP_SECRET = "CHANGEME";
      };
      volumes = [
        "${cfg.dataDir}/registry:/storage"
        "${cfg.dataDir}/config/registry/:/etc/registry/:ro"
      ];
    };
    virtualisation.oci-containers.containers."harbor-registryctl" = {
      autoStart = true;
      image = "docker.io/bitnami/harbor-registryctl:2";
      extraOptions = ["--pull=newer"];
      environment = {
        CORE_SECRET = "CHANGEME";
        JOBSERVICE_SECRET = "CHANGEME";
        REGISTRY_HTTP_SECRET = "CHANGEME";
      };
      volumes = [
        "${cfg.dataDir}/registry:/storage"
        "${cfg.dataDir}/config/registry/:/etc/registry/:ro"
        "${cfg.dataDir}/config/registryctl/config.yml:/etc/registryctl/config.yml:ro"
      ];
    };
    virtualisation.oci-containers.containers."harbor-db" = {
      autoStart = true;
      image = "docker.io/bitnami/postgresql:14";
      extraOptions = ["--pull=newer"];
      environment = {
        POSTGRESQL_PASSWORD = "bitnami";
        POSTGRESQL_DATABASE = "registry";
      };
      volumes = [
        "${cfg.dataDir}/postgresql:/bitnami/postgresql"
      ];
    };
    virtualisation.oci-containers.containers."harbor-core" = {
      autoStart = true;
      image = "docker.io/bitnami/harbor-core:2";
      extraOptions = ["--pull=newer"];
      dependsOn = [ "harbor-registry" ];
      environment = {
        EXT_ENDPOINT = "http://${cfg.domain}";
        PORT = "8080";
        HARBOR_ADMIN_PASSWORD = "bitnami";
        DATABASE_TYPE = "postgresql";
        POSTGRESQL_HOST = "postgresql";
        POSTGRESQL_PORT = "5432";
        POSTGRESQL_DATABASE = "registry";
        POSTGRESQL_USERNAME = "postgres";
        POSTGRESQL_PASSWORD = "bitnami";
        POSTGRESQL_SSLMODE = "disable";
        CHART_CACHE_DRIVER = "redis";
        _REDIS_URL_CORE = "redis://redis:6379/0";
        _REDIS_URL_REG = "redis://redis:6379/1";
        REGISTRY_URL = "http://registry:5000";
        REGISTRY_CONTROLLER_URL = "http://registryctl:8080";
        CORE_URL = "http://core:8080";
        CORE_KEY = "change-this-key";
        CORE_SECRET = "CHANGEME";
        TOKEN_SERVICE_URL = "http://core:8080/service/token";
        JOBSERVICE_URL = "http://jobservice:8080";
        JOBSERVICE_SECRET = "CHANGEME";
        REGISTRY_STORAGE_PROVIDER_NAME = "filesystem";
        REGISTRY_CREDENTIAL_USERNAME = "harbor_registry_user";
        REGISTRY_CREDENTIAL_PASSWORD = "harbor_registry_password";
        LOG_LEVEL = "info";
        SYNC_REGISTRY = "false";
        ADMIRAL_URL = "";
        READ_ONLY = "false";
        RELOAD_KEY = "";
      };
      volumes = [
        "${cfg.dataDir}/core:/data"
        "${cfg.dataDir}/config/core/app.conf:/etc/core/app.conf:ro"
        "${cfg.dataDir}/config/core/private_key.pem:/etc/core/private_key.pem:ro"
      ];
    };
    virtualisation.oci-containers.containers."harbor-portal" = {
      autoStart = true;
      image = "docker.io/bitnami/harbor-portal:2";
      extraOptions = ["--pull=newer"];
      dependsOn = [ "harbor-core" ];
    };
    virtualisation.oci-containers.containers."harbor-jobservice" = {
      autoStart = true;
      image = "docker.io/bitnami/harbor-jobservice:2";
      extraOptions = ["--pull=newer"];
      dependsOn = [ "harbor-core" "harbor-redis" ];
      environment = {
        CORE_URL = "http://core:8080";
        CORE_SECRET = "CHANGEME";
        JOBSERVICE_SECRET = "CHANGEME";
        REGISTRY_CONTROLLER_URL = "http://registryctl:8080";
        REGISTRY_CREDENTIAL_USERNAME = "harbor_registry_user";
        REGISTRY_CREDENTIAL_PASSWORD = "harbor_registry_password";
      };
      volumes = [
        "${cfg.dataDir}/jobs:/var/log/jobs"
        "${cfg.dataDir}/config/jobservice/config.yml:/etc/jobservice/config.yml:ro"
      ];
    };
    virtualisation.oci-containers.containers."harbor-redis" = {
      autoStart = true;
      image = "docker.io/bitnami/redis:latest";
      extraOptions = ["--pull=newer"];
      environment = {
        ALLOW_EMPTY_PASSWORD = "yes";
      };
    };
    virtualisation.oci-containers.containers."harbor-trivy" = {
      autoStart = true;
      image = "docker.io/bitnami/harbor-adapter-trivy:2";
      extraOptions = ["--pull=newer"];
      environment = {
        SCANNER_LOG_LEVEL = "info";
        SCANNER_REDIS_URL = "redis://redis:6379/5?idle_timeout_seconds=30";
        SCANNER_STORE_REDIS_URL = "redis://redis:6379/5?idle_timeout_seconds=30";
        SCANNER_STORE_REDIS_NAMESPACE = "harbor.scanner.trivy:store";
        SCANNER_JOB_QUEUE_REDIS_URL = "redis://redis:6379/5?idle_timeout_seconds=30";
        SCANNER_JOB_QUEUE_REDIS_NAMESPACE = "harbor.scanner.trivy:job-queue";
        SCANNER_TRIVY_CACHE_DIR = "/home/scanner/.cache/trivy";
        SCANNER_TRIVY_REPORTS_DIR = "/home/scanner/.cache/reports";
        SCANNER_TRIVY_VULN_TYPE = "os,library";
        SCANNER_TRIVY_SEVERITY = "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL";
        SCANNER_TRIVY_IGNORE_UNFIXED = "False";
        SCANNER_TRIVY_SKIP_UPDATE = "False";
        SCANNER_TRIVY_SKIP_JAVA_DB_UPDATE = "False";
        SCANNER_TRIVY_OFFLINE_SCAN = "False";
        SCANNER_TRIVY_SECURITY_CHECKS = "vuln";
        SCANNER_TRIVY_GITHUB_TOKEN = "";
        SCANNER_TRIVY_INSECURE = "False";
        SCANNER_TRIVY_TIMEOUT = "5m0s";
        HTTP_PROXY = "";
        HTTPS_PROXY = "";
        NO_PROXY = "localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
      };
      volumes = [
        "${cfg.dataDir}/scanner/trivy:/home/scanner/.cache/trivy"
        "${cfg.dataDir}/scanner/reports:/home/scanner/.cache/reports"
      ];
    };
  };
}
