{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.garage;
  reverseProxyCaddy = config.modules.services.caddy;
  configFile = ./garage.toml;
in {
  options.modules.services.garage = {
    enable = lib.mkEnableOption "garage";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "s3.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [3900];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:3900
      }
    '';

    environment.systemPackages = [pkgs.unstable.garage];

    # Garage Versioning not implemented;
    # Garage use key/bucket logic instead of Policy;
    # Garage Lifecycle supports only `AbortIncompleteMultipartUpload` and `Expiration` (without `ExpiredObjectDeleteMarker`);

    environment.etc."garage.toml" = {
      user = "appuser";
      group = "appuser";
      mode = "0600";
      source = pkgs.writeText "garage.toml" "${configFile}";
    };
    systemd.tmpfiles.rules = [
      "d /var/lib/garage 0755 appuser appuser - -"
      "d /var/lib/garage/data 0755 appuser appuser - -"
      "d /var/lib/garage/meta 0755 appuser appuser - -"
    ];

    systemd.services.garage = {
      description = "S3-compatible object store for small self-hosted geo-distributed deployments";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.unstable.garage}/bin/garage server";
        RuntimeDirectory = "garage";
        StateDirectory = "garage";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
