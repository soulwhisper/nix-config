{
  config,
  lib,
  pkgs,
  ...
}:
let
  pki = config.services.pki;
  forgejo = config.services.forgejo;
  pkiEnabled = pki.enable or false;
  forgejoEnabled = forgejo.enable or false;
  python = pkgs.python3.withPackages (p: [ p.cryptography ]);
  backupOptions = {
    recipient = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Public age recipient for manual and daily encrypted backups.";
    };
    identityFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Root-owned runtime age identity used only for approved restoration.";
    };
  };
  pkiBackup = pkiEnabled && pki.backup.recipient != null;
  forgejoBackup = forgejoEnabled && forgejo.backup.recipient != null;
  runtimeConfig = (pkgs.formats.json { }).generate "corp-service-maintenance.json" {
    hostname = config.networking.hostName;
    tools = {
      age = "${pkgs.age}/bin/age";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      runuser = "${pkgs.util-linux}/bin/runuser";
    }
    // lib.optionalAttrs forgejoEnabled {
      pgBin = "${pkgs.postgresql_18}/bin";
    };
    pki = {
      enable = pkiEnabled;
    }
    // lib.optionalAttrs pkiEnabled {
      domain = "pki.internal.htkrail.com";
      stateDir = "/var/lib/step-ca";
      materials = {
        root = pki.rootCertificateFile;
        certificate = pki.intermediateCertificateFile;
        key = pki.intermediateKeyFile;
        password = pki.intermediatePasswordFile;
      }
      // lib.optionalAttrs (pki.rootCRLFile != null) {
        crl = pki.rootCRLFile;
      };
      validationCommand = [
        "${python}/bin/python"
        "${./validate-materials.py}"
        "--config"
        "/etc/step-ca/materials.json"
      ];
      backup = {
        inherit (pki.backup) recipient identityFile;
        directory = "/var/backup/corp/pki";
      };
    };
    forgejo = {
      enable = forgejoEnabled;
    }
    // lib.optionalAttrs forgejoEnabled {
      inherit (forgejo) domain;
      stateDir = "/var/lib/forgejo";
      binary = "${pkgs.corp-forgejo}/bin/forgejo";
      version = pkgs.corp-forgejo.version;
      backup = {
        inherit (forgejo.backup) recipient identityFile;
        directory = "/var/backup/corp/forgejo";
      };
    };
  };
  executor = pkgs.writeShellScriptBin "corp-service-maintenance" ''
    set -euo pipefail
    exec ${pkgs.python3}/bin/python ${./maintenance.py} --config ${runtimeConfig} "$@"
  '';
in
{
  options.services = {
    pki.backup = backupOptions;
    forgejo.backup = backupOptions;
  };

  config = lib.mkIf (pkiEnabled || forgejoEnabled) {
    environment.systemPackages = [ executor ];

    systemd.services.corp-pki-backup = lib.mkIf pkiBackup {
      description = "Consistent encrypted PKI backup";
      serviceConfig = {
        Type = "oneshot";
        UMask = "0077";
        ExecStart = "${executor}/bin/corp-service-maintenance pki-backup";
      };
    };
    systemd.services.corp-forgejo-backup = lib.mkIf forgejoBackup {
      description = "Consistent encrypted Forgejo backup";
      serviceConfig = {
        Type = "oneshot";
        UMask = "0077";
        ExecStart = "${executor}/bin/corp-service-maintenance forgejo-backup";
      };
    };
    systemd.timers.corp-pki-backup = lib.mkIf pkiBackup {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
    systemd.timers.corp-forgejo-backup = lib.mkIf forgejoBackup {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };
  };
}
