{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.minio;
in
{
  options.modules.services.minio = {
    enable = lib.mkEnableOption "minio";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/minio/data";
    };
    rootCredentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."s3.noirprime.com".extraConfig = ''
      handle_path /console/* {
	      reverse_proxy localhost:9001
      }
      handle {
	      reverse_proxy localhost:9000
      }
    '';

    # networking.firewall.allowedTCPPorts = [ 9000 9001 ];

    services.minio = {
      enable = true;
      package = pkgs.unstable.minio;
      dataDir = [
        cfg.dataDir
      ];
      inherit (cfg) rootCredentialsFile;
    };
  };
}
