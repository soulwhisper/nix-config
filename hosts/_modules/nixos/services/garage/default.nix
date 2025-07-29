{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.garage;
  reverseProxyCaddy = config.modules.services.caddy;
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
      source = (pkgs.formats.toml {}).generate "garage.toml" {
        # ref:https://garagehq.deuxfleurs.fr/documentation/quick-start/
        # ref:https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/
        metadata_dir = "/var/lib/garage/meta";
        data_dir = "/var/lib/garage/data";
        db_engine = "sqlite";
        replication_factor = 1;
        rpc_bind_addr = "[::]:3901";
        rpc_public_addr = "127.0.0.1:3901";
        rpc_secret = "180f83ddd22e289bae0cc2ada61abccd667810e9e486469e09f9f2de980b51ad";
        s3_api.s3_region = "us-east-1";
        s3_api.api_bind_addr = "[::]:3900";
        s3_api.root_domain = ".${cfg.domain}";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/garage 0755 appuser appuser - -"
      "d /var/lib/garage/meta 0755 appuser appuser - -"
      "d /var/lib/garage/data 0755 appuser appuser - -"
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
