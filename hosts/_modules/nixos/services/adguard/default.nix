{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.adguard;
in
{
  options.modules.services.adguard = {
    enable = lib.mkEnableOption "adguard";
  };

  config = lib.mkIf cfg.enable {
    networking.resolvconf.useLocalResolver = lib.mkForce false;

    environment.etc = {
        "adguard/AdGuardHome.yaml".source = pkgs.writeTextFile {
        name = "AdGuardHome.yaml";
        text = builtins.readFile ./AdGuardHome.yaml;
        };
    };

    networking.firewall.allowedTCPPorts = [ 53 3000 ];
    networking.firewall.allowedUDPPorts = [ 53 67 68 ];

    systemd.services.adguard = {
      description = "AdGuard Home: Network-level blocker";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        StartLimitIntervalSec = 5;
        StartLimitBurst = 10;
      };
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${pkgs.unstable.adguardhome}/bin/adguardhome \
                    --no-check-update \
                    --pidfile /run/AdGuardHome/AdGuardHome.pid \
                    --work-dir /var/lib/AdGuardHome/ \
                    --config /etc/adguard/AdGuardHome.yaml";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
        Restart = "always";
        RestartSec = 10;
        RuntimeDirectory = "AdGuardHome";
        StateDirectory = "AdGuardHome";
      };
    };
  };
}
