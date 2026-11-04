{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pki;
  python = pkgs.python3.withPackages (p: [ p.cryptography ]);
  materials = {
    root = cfg.rootCertificateFile;
    certificate = cfg.intermediateCertificateFile;
    key = cfg.intermediateKeyFile;
    password = cfg.intermediatePasswordFile;
  }
  // lib.optionalAttrs (cfg.rootCRLFile != null) { crl = cfg.rootCRLFile; };
  credentials = lib.mapAttrsToList (name: path: "${name}:${path}") materials;
  validator = "${python}/bin/python ${./validate-materials.py} --config /etc/step-ca/materials.json";
  domains = lib.unique (
    cfg.allowedDomains
    ++ [ "pki.internal.htkrail.com" ]
    ++ lib.optional config.services.forgejo.enable config.services.forgejo.domain
  );
in
{
  imports = [ ./maintenance.nix ];

  options.services.pki = {
    enable = lib.mkEnableOption "the SOPS-fed corporate ACME issuer";
    rootCertificateFile = lib.mkOption {
      type = lib.types.path;
      description = "Runtime SOPS path to the public root certificate; never a private root key.";
    };
    intermediateCertificateFile = lib.mkOption {
      type = lib.types.path;
      description = "Runtime SOPS path to the root-signed pathlen:0 intermediate certificate.";
    };
    intermediateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Runtime SOPS path to the encrypted intermediate private key.";
    };
    intermediatePasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Runtime SOPS path to the intermediate key password.";
    };
    rootCRLFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional current offline-root CRL, validated and published with the root.";
    };
    allowedDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional exact DNS names allowed for issuance; no wildcard certificates or patterns.";
    };
    deniedDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Exact DNS names denied even if present in the allow list.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."step-ca/materials.json".source =
      (pkgs.formats.json { }).generate "step-ca-materials.json"
        {
          inherit materials;
          fingerprint = null;
        };
    environment.etc."step-ca/ca.json".source = (pkgs.formats.json { }).generate "step-ca.json" {
      address = "127.0.0.1:9700";
      root = "/run/credentials/step-ca.service/root";
      crt = "/run/credentials/step-ca.service/certificate";
      key = "/run/credentials/step-ca.service/key";
      dnsNames = [ "localhost" ];
      db = {
        type = "badgerv2";
        dataSource = "/var/lib/step-ca/db";
      };
      logger.format = "json";
      authority = {
        enableAdmin = false;
        claims = {
          minTLSCertDuration = "5m";
          defaultTLSCertDuration = "168h";
          maxTLSCertDuration = "168h";
          disableRenewal = true;
          allowRenewalAfterExpiry = false;
        };
        policy.x509 = {
          allow.dns = domains;
          deny.dns = cfg.deniedDomains;
          allowWildcardNames = false;
        };
        provisioners = [
          {
            type = "ACME";
            name = "acme";
            challenges = [ "tls-alpn-01" ];
          }
        ];
      };
      tls = {
        minVersion = 1.2;
        maxVersion = 1.3;
        renegotiation = false;
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/step-ca 0700 appuser appuser - -"
      "d /var/lib/step-ca/db 0700 appuser appuser - -"
    ];

    systemd.services.step-ca = {
      description = "Corporate ACME intermediate certificate authority";
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "pki-publish.service"
      ];
      requires = [ "pki-publish.service" ];
      wantedBy = [ "multi-user.target" ];
      # Restart, never HUP: systemd must load a fresh password and key snapshot.
      reloadIfChanged = false;
      restartTriggers = [
        config.environment.etc."step-ca/ca.json".source
        config.environment.etc."step-ca/materials.json".source
      ];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStartPre = "${validator} --credentials";
        ExecStart = "${pkgs.unstable.step-ca}/bin/step-ca /etc/step-ca/ca.json --password-file=%d/password";
        LoadCredential = credentials;
        StateDirectory = "step-ca";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/step-ca";
        Restart = "always";
        RestartSec = 5;
        UMask = "0077";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    systemd.services.pki-publish = {
      description = "Publish corporate PKI public artifacts";
      wantedBy = [ "multi-user.target" ];
      before = [
        "step-ca.service"
        "caddy.service"
      ];
      restartTriggers = [ config.environment.etc."step-ca/materials.json".source ];
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "pki-public";
        RuntimeDirectoryMode = "0755";
        LoadCredential = [
          "root:${cfg.rootCertificateFile}"
        ]
        ++ lib.optional (cfg.rootCRLFile != null) "crl:${cfg.rootCRLFile}";
        UMask = "0022";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
      script = ''
        set -euo pipefail
        ${pkgs.coreutils}/bin/install -m 0444 "$CREDENTIALS_DIRECTORY/root" /run/pki-public/root_ca.crt
        ${lib.optionalString (
          cfg.rootCRLFile != null
        ) ''${pkgs.coreutils}/bin/install -m 0444 "$CREDENTIALS_DIRECTORY/crl" /run/pki-public/root.crl''}
      '';
    };

    systemd.services.caddy = lib.mkIf config.services.caddy.enable {
      requires = [ "pki-publish.service" ];
      after = [
        "pki-publish.service"
        "step-ca.service"
      ];
    };
    services.caddy.extraConfig = lib.mkIf config.services.caddy.enable ''
      (corp_pki_tls) {
        tls {
          issuer acme {
            dir https://localhost:9700/acme/acme/directory
            trusted_roots /run/pki-public/root_ca.crt
            disable_http_challenge
          }
        }
      }
    '';
    services.caddy.virtualHosts."pki.internal.htkrail.com".extraConfig =
      lib.mkIf config.services.caddy.enable ''
        import corp_pki_tls
        @public path /root_ca.crt${lib.optionalString (cfg.rootCRLFile != null) " /root.crl"}
        handle @public {
          root * /run/pki-public
          file_server
        }
        handle {
          respond "Not found" 404
        }
      '';
  };
}
