{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.corpServiceMaintenance;
  enabled = cfg.pki.enable || cfg.forgejo.enable;
  backupOptions = service: {
    enable = lib.mkEnableOption "scheduled encrypted ${service} backups";
    recipient = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "age encryption recipient (public); required for manual and scheduled backups.";
    };
    directory = lib.mkOption {
      type = lib.types.str;
      default = "/var/backup/corp/${service}";
      description = "Root-only encrypted backup output directory.";
    };
    identityFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Runtime root-owned mode0600 age identity for explicitly approved restores; never read at evaluation.";
    };
    calendar = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd calendar for encrypted backups.";
    };
  };
  backups = {
    pki = config.services.pki.backup;
    forgejo = config.services.forgejo.backup;
  };
  runtimeConfig = pkgs.writeText "corp-service-maintenance.json" (
    builtins.toJSON {
      hostname = config.networking.hostName;
      tools = {
        age = "${pkgs.age}/bin/age";
        systemctl = "${pkgs.systemd}/bin/systemctl";
        runuser = "${pkgs.util-linux}/bin/runuser";
        pgBin = "${pkgs.postgresql_18}/bin";
      };
      pki = cfg.pki // {
        backup = backups.pki;
      };
      forgejo =
        (removeAttrs cfg.forgejo [ "package" ])
        // lib.optionalAttrs cfg.forgejo.enable {
          binary = "${cfg.forgejo.package}/bin/forgejo";
          version = cfg.forgejo.package.version;
          backup = backups.forgejo;
        };
    }
  );
  executor = pkgs.writeScriptBin "corp-service-maintenance" ''
    #!${pkgs.runtimeShell}
    set -euo pipefail
    exec ${pkgs.python3}/bin/python ${./maintenance.py} --config ${runtimeConfig} "$@"
  '';
in
{
  options.services = {
    pki.backup = backupOptions "pki";
    forgejo.backup = backupOptions "forgejo";
    corpServiceMaintenance = {
      pki = lib.mkOption {
        internal = true;
        type = lib.types.attrsOf lib.types.anything;
        default = {
          enable = false;
        };
      };
      forgejo = lib.mkOption {
        internal = true;
        type = lib.types.attrsOf lib.types.anything;
        default = {
          enable = false;
        };
      };
    };
  };
  config = lib.mkIf enabled {
    assertions =
      lib.concatMap
        (
          service:
          let
            backup = backups.${service};
          in
          [
            {
              assertion =
                !backup.enable || (cfg.${service}.enable && backup.recipient != null && backup.recipient != "");
              message = "Scheduled ${service} backup requires the service and a real public age recipient.";
            }
            {
              assertion =
                lib.hasPrefix "/" backup.directory
                && backup.directory != "/"
                && !(lib.hasPrefix builtins.storeDir backup.directory);
              message = "${service} backup directory must be an absolute runtime path.";
            }
            {
              assertion =
                backup.identityFile == null
                || (
                  lib.hasPrefix "/" (toString backup.identityFile)
                  && !(lib.hasPrefix builtins.storeDir (toString backup.identityFile))
                );
              message = "${service} restore identity must be an absolute runtime secret path outside the store.";
            }
          ]
        )
        [
          "pki"
          "forgejo"
        ];
    environment.systemPackages = [ executor ];
    systemd.services =
      lib.genAttrs
        (map (name: "corp-${name}-backup") [
          "pki"
          "forgejo"
        ])
        (
          unit:
          let
            service = if unit == "corp-pki-backup" then "pki" else "forgejo";
          in
          lib.mkIf backups.${service}.enable {
            description = "Consistent encrypted ${service} backup";
            serviceConfig = {
              Type = "oneshot";
              UMask = "0077";
              ExecStart = "${executor}/bin/corp-service-maintenance ${service}-backup";
            };
          }
        );
    systemd.timers =
      lib.genAttrs
        (map (name: "corp-${name}-backup") [
          "pki"
          "forgejo"
        ])
        (
          unit:
          let
            service = if unit == "corp-pki-backup" then "pki" else "forgejo";
          in
          lib.mkIf backups.${service}.enable {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = backups.${service}.calendar;
              Persistent = true;
              RandomizedDelaySec = "30m";
            };
          }
        );
  };
}
