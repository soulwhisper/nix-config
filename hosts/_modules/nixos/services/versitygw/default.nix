{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.versitygw;
in {
  options.modules.services.versitygw = {
    enable = lib.mkEnableOption "versitygw";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  # versitygw disable caddy to keep compatibility with TrueNAS / Synology;
  # endpoint = http://nas.homelab.internal:9000;
  # port conflict with minio/garage;

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9000];

    # Disable IAM service for simplicity
    # Backend Performance: xfs/btrfs > ext4/zfs

    systemd.tmpfiles.rules = [
      "d /var/lib/versitygw 0755 appuser appuser - -"
      "d /var/lib/versitygw/data 0755 appuser appuser - -"
    ];

    systemd.services.versitygw = {
      description = "Versity S3 Gateway, a high-performance S3 translation service";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.unstable.versitygw}/bin/versitygw --port :9000 posix /var/lib/versitygw/data";
        RuntimeDirectory = "versitygw";
        StateDirectory = "versitygw";
        Restart = "always";
        RestartSec = 5;
        EnvironmentFile = [
          "${cfg.authFile}"
        ];
      };
    };
  };
}
