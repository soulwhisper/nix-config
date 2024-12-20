{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.ddns;
in
{
  # ddns-go cant read env-file correct, config via :9901
  options.modules.services.ddns = {
    enable = lib.mkEnableOption "ddns";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 9901 ];

    systemd.services.ddns = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      unitConfig = {
        Description = "DDNS update service";
      };
      serviceConfig = {
        TimeoutSec = "5min";
        ExecStartPre =
        [
          "/bin/sh -c '[[ -f config.yaml ]] || touch config.yaml'"
        ];
        ExecStart = "${lib.getExe pkgs.unstable.ddns-go} -l :9901 -f 600 -c /var/lib/ddns/config.yaml";
        StateDirectory = "ddns";
        Restart = "on-failure";
      };
    };
  };
}
