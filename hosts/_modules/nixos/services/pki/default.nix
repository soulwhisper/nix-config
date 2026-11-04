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
    root = toString cfg.rootCertificateFile;
    certificate = toString cfg.intermediateCertificateFile;
    key = toString cfg.intermediateKeyFile;
    password = toString cfg.intermediatePasswordFile;
  }
  // lib.optionalAttrs (cfg.rootCRLFile != null) { crl = toString cfg.rootCRLFile; };
  validationConfig = pkgs.writeText "pki-validation.json" (
    builtins.toJSON {
      inherit materials;
      fingerprint = cfg.rootFingerprint;
    }
  );
  validator = "${python}/bin/python ${./validate-materials.py} --config ${validationConfig}";
  domains = lib.unique (
    cfg.allowedDomains
    ++ [ cfg.domain ]
    ++ lib.optional config.services.forgejo.enable config.services.forgejo.settings.server.DOMAIN
  );
  domainPattern = "([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z]([a-z0-9-]*[a-z0-9])?";
  validDomain =
    value:
    builtins.match domainPattern value != null
    && builtins.stringLength value <= 253
    && lib.all (label: builtins.stringLength label <= 63) (lib.splitString "." value);
in
{
  imports = [ ./maintenance.nix ];
  options.services.pki = {
    enable = lib.mkEnableOption "the SOPS-fed corporate ACME issuer";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "pki.internal.htkrail.com";
      description = "Canonical HTTPS publication hostname.";
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Loopback-only issuer address.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9700;
    };
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
    rootFingerprint = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.strMatching "([0-9a-fA-F]{64}|([0-9a-fA-F]{2}:){31}[0-9a-fA-F]{2})"
      );
      default = null;
      description = "Optional independently verified SHA256 root certificate fingerprint.";
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
    assertions = [
      {
        assertion = cfg.address == "127.0.0.1";
        message = "Corporate PKI must remain bound to IPv4 loopback.";
      }
      {
        assertion = lib.all validDomain (domains ++ cfg.deniedDomains);
        message = "PKI domains must be canonical lowercase exact DNS hostnames, without wildcard, URI, port or IP literals.";
      }
      {
        assertion = !(lib.elem cfg.domain cfg.deniedDomains);
        message = "The PKI publication domain cannot be denied.";
      }
      {
        assertion = lib.all (path: lib.hasPrefix "/" path && !(lib.hasPrefix builtins.storeDir path)) (
          lib.attrValues materials
        );
        message = "PKI material must be runtime absolute file paths outside the Nix store.";
      }
    ];
    services.step-ca = {
      enable = true;
      package = pkgs.unstable.step-ca;
      inherit (cfg) address port;
      openFirewall = false;
      intermediatePasswordFile = toString cfg.intermediatePasswordFile;
      settings = {
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
    };
    systemd.services.step-ca = {
      # Never HUP on material/configuration changes: credentials must be loaded afresh.
      reloadIfChanged = lib.mkForce false;
      serviceConfig = {
        # A permanent issuer account keeps the Badger directory directly owned
        # and addressable for stopped-service backup and guarded restore.
        DynamicUser = lib.mkForce false;
        StateDirectoryMode = "0700";
        ExecReload = lib.mkForce [ ];
        LoadCredential = lib.mkForce (
          lib.mapAttrsToList (name: path: "${name}:${path}") materials
          ++ [ "intermediate_password:${toString cfg.intermediatePasswordFile}" ]
        );
        ExecStartPre = [ "${validator} --credentials" ];
      };
    };
    systemd.services.pki-publish = {
      description = "Validate and publish only corporate PKI public artifacts";
      wantedBy = [ "multi-user.target" ];
      before = [
        "step-ca.service"
        "caddy.service"
      ];
      requiredBy = [ "step-ca.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "pki-public";
        RuntimeDirectoryMode = "0755";
        LoadCredential = lib.mapAttrsToList (name: path: "${name}:${path}") materials;
        UMask = "0022";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
      script = ''
        set -euo pipefail
        ${validator} --credentials > /dev/null
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
            dir https://localhost:${toString cfg.port}/acme/acme/directory
            trusted_roots /run/pki-public/root_ca.crt
            disable_http_challenge
          }
        }
      }
    '';
    services.caddy.virtualHosts.${cfg.domain}.extraConfig = lib.mkIf config.services.caddy.enable ''
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
    services.corpServiceMaintenance.pki = {
      enable = true;
      inherit materials;
      inherit (cfg) domain;
      validationCommand = [
        "${python}/bin/python"
        "${./validate-materials.py}"
        "--config"
        "${validationConfig}"
      ];
    };
  };
}
