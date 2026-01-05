{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.vector;
in {
  options.modules.services.vector = {
    enable = lib.mkEnableOption "vector";
    sinks.endpoints = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "http://logs.noirprime.com/insert/elasticsearch/" ];
      description = ''
        List of Vector sink endpoints to send logs to VictoriaLogs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [514];
    networking.firewall.allowedUDPPorts = [514];

    # : Unifi
    # Settings -> System -> Advanced -> Remote Logging, Port 514
    # : Synology
    # Log Center -> Log Sending, Port 514, Protocol TCP, Format BSD (RFC 3164)
    # : K8S without vlogs
    # udp://ip:514, format: rfc5424
    # : Ignore list
    # IOT/Smart devices, Printers, L2 switches, TVs, etc.

    services.vector = {
      enable = true;
      gracefulShutdownLimitSecs = 60;
      journaldAccess = true;
      validateConfig = true;
      settings = {
        sources = {
          syslog_in_udp = {
            type = "syslog";
            address = "0.0.0.0:514";
            mode = "udp";
            max_length = 102400;
          };
          syslog_in_tcp = {
            type = "syslog";
            address = "0.0.0.0:514";
            mode = "tcp";
          };
        };
        transforms = {
          syslog_formatted = {
            type = "remap";
            inputs = [ "syslog_in_udp" "syslog_in_tcp" ];
            source = ''
              .host = string(.host) ?? "unknown_device"
              let host_lower = downcase(.host)
              ._stream = host_lower
              del(.source_type)
            '';
          };
        };
        sinks = {
          to_victoria_logs = {
            type = "elasticsearch";
            inputs = [ "syslog_formatted" ];
            endpoints = cfg.sinks.endpoints;
            mode = "bulk";
            compression = "gzip";
            batch = {
              max_bytes = 2097152; # 2MB
              timeout_secs = 1;
            };
            acknowledgements.enabled = true;
            healthcheck.enabled = true;
            buffer = {
              type = "disk";
              max_size = 4294967296; # 4GB
              when_full = "drop_newest";
            };
          };
        };
      };
    };
  };
}
