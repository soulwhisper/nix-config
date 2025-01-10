{
  lib,
  pkgs,
  config,
  hostname,
  ...
}:
let
  cfg = config.modules.services;

  alloyConfigs = lib.fold lib.recursiveUpdate {} [
    ({
      logging {
	      level = "info"
	      format = "logfmt"
      }
    })
    (lib.mkIf cfg.exporters.enable {
      prometheus.scrape "hostname_node" {
        targets    = [{"__address__" = "localhost:9100"}]
        forward_to = [prometheus.remote_write.default.receiver]
        job_name   = "node"
        scrape_interval = "15s"
      }
    })
    (lib.mkIf cfg.nut.enable {
      prometheus.scrape "hostname_nut" {
        targets    = [{"__address__" = "localhost:9101"}]
        forward_to = [prometheus.remote_write.default.receiver]
        job_name   = "nut"
        scrape_interval = "15s"
      }
    })
    (lib.mkIf cfg.smartd.enable {
      prometheus.scrape "hostname_smartctl" {
        targets    = [{"__address__" = "localhost:9102"}]
        forward_to = [prometheus.remote_write.default.receiver]
        job_name   = "smartctl"
        scrape_interval = "15s"
      }
    })
    ({
      prometheus.remote_write "default" {
        endpoint {
        url = "http://${prom_host}:${prom_port}/api/v1/prom/remote/write"
        }
      }
    })
  ];
in
{
  options.modules.services.monitroing.alloy = {
    prom_host = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
    };
    prom_port = lib.mkOption {
      type = lib.types.str;
      default = "9090";
    };
  };

  config = {
    environment.etc = {
        "alloy/config.alloy".source = pkgs.writeTextFile {
        name = "config.alloy";
        text = alloyConfigs;
        };
    };

    services.alloy = {
      enable = true;
      configPath = "/etc/alloy";
      extraFlags = [];
    };
  };
}
