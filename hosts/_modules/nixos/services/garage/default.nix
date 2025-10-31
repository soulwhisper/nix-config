{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.garage;
in {
  options.modules.services.garage = {
    enable = lib.mkEnableOption "garage";
  };

  # garage disable caddy to keep compatibility with TrueNAS / Synology;
  # endpoint = http://nas.homelab.internal:9000;
  # port conflict with minio/versitygw;

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [9000];

    environment.systemPackages = [pkgs.unstable.garage];

    # : Garage Versioning not implemented;
    # : Garage use key/bucket logic instead of Policy;
    # : Garage Lifecycle supports only `AbortIncompleteMultipartUpload` and `Expiration` (without `ExpiredObjectDeleteMarker`);

    # : run below commands to bootstrap this service
    # garage status
    # garage layout assign -z main -c 100G node-id/prefix
    # garage layout apply --version 1

    # : this config setup a local-managed rep1 Garage instance

    environment.etc."garage.toml" = {
      user = "appuser";
      group = "appuser";
      mode = "0644";
      source = (pkgs.formats.toml {}).generate "garage.toml" {
        # ref:https://garagehq.deuxfleurs.fr/documentation/quick-start/
        # ref:https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/
        metadata_dir = "/var/lib/garage/meta";
        data_dir = "/var/lib/garage/data";
        db_engine = "sqlite";
        replication_factor = 1;
        rpc_bind_addr = "[::]:9001";
        rpc_public_addr = "127.0.0.1:9001";
        rpc_secret = "180f83ddd22e289bae0cc2ada61abccd667810e9e486469e09f9f2de980b51ad";
        s3_api.s3_region = "us-east-1";
        s3_api.api_bind_addr = "[::]:9000";
        # s3_api.root_domain = ".${cfg.domain}";
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
