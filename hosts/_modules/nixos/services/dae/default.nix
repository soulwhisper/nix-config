{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.dae;
in
{
  options.modules.services.dae = {
    enable = lib.mkEnableOption "dae";
    subscriptionFile = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "The Shadowsocks links for the dae subscription.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "dae/config.dae".source = pkgs.writeText "config.dae" (builtins.readFile ./config.dae);
      "dae/config.dae".mode = "0400";

      "dae/update-dae-subs.sh".source = pkgs.writeTextFile {
        name = "update-dae-subs.sh";
        text = builtins.readFile ./update-dae-subs.sh;
        executable = true;
      };
    };

    systemd.services.dae = {
      description = "Dae Service";
      documentation = [ "https://github.com/daeuniverse/dae" ];
      after = [ "network.target" "systemd-sysctl.service" "dbus.service" ];
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        PIDFile = "/run/dae.pid";
        ExecStartPre = "${pkgs.unstable.dae}/bin/dae validate -c /etc/dae/config.dae";
        ExecStart = "${pkgs.unstable.dae}/bin/dae run --disable-timestamp -c /etc/dae/config.dae";
        ExecReload = "${pkgs.unstable.dae}/bin/dae reload $MAINPID";
        Restart = "always";
      };
    };

    systemd.services.update-dae-subs = {
      description = "Update DAE Subscription Service";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      preStart = ''
        if [ -n "${cfg.subscriptionFile}" ] && [ -f "${cfg.subscriptionFile}" ]; then
          echo $(cat ${cfg.subscriptionFile}) > /etc/dae/sublist
        else
          echo "CHANGEME" > /etc/dae/sublist
        fi
      '';
      serviceConfig = {
        ExecStart = "/etc/dae/update-dae-subs.sh";
        Restart= "on-failure";
      };
    };

    systemd.timers.update-dae-subs = {
      description = "Run Update DAE Subscription Script Periodically";
      timerConfig = {
        OnBootSec = "15min";
        OnUnitActiveSec = "12h";
      };
      wantedBy = [ "timers.target" ];
    };

    systemd.services.dae.before = [ "update-dae-subs.timer" ];

    services.tinyproxy = {
      enable = true;
      settings = {
          Port = 1080;
          Listen = "0.0.0.0";
        };
    };

    networking.firewall.allowedTCPPorts = [ 1080 ];
  };
}
