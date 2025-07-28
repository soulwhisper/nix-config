{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.versitygw;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.versitygw = {
    enable = lib.mkEnableOption "versitygw";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "s3.noirprime.com";
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [7070];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:7070
      }
    '';

    # Disable IAM service for simplicity
    # Backend Performance: xfs/btrfs > ext4/zfs

    systemd.tmpfiles.rules = [
      "d /var/lib/versitygw 0755 appuser appuser - -"
      "d /var/lib/versitygw/data 0755 appuser appuser - -"
      # "d /var/lib/versitygw/users 0755 appuser appuser - -"
    ];

    systemd.services.versitygw = {
      description = "Versity S3 gateway, a high-performance S3 translation service";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        # ExecStart = "${pkgs.unstable.versitygw}/bin/versitygw --iam-dir /var/lib/versitygw/users posix /var/lib/versitygw/data";
        ExecStart = "${pkgs.unstable.versitygw}/bin/versitygw posix /var/lib/versitygw/data";
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
