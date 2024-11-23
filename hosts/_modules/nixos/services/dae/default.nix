{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.dae;

  # remove spaces and quotes from subscription-link
  removeQuotes = str: builtins.replaceStrings ["\""] [""] str;
  removeSpaces = str: builtins.replaceStrings [" "] [""] str;
  cleanString = str: removeSpaces (removeQuotes str);
in
{
  options.modules.services.dae = {
    enable = lib.mkEnableOption "dae";
    subscription = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "The URL for the dae subscription, in SS style.";
    };
  };

  config = lib.mkIf cfg.enable {

    services.dae = {
      enable = true;
      package = pkgs.unstable.dae;
      configFile = "/etc/dae/config.dae";
    };

    environment.etc = {
      "dae/config.dae".source = pkgs.writeText "config.dae" (builtins.readFile ./config.dae);
      "dae/config.dae".mode = "0400";

      "dae/sublist".source = pkgs.writeText "sublist" ("subscription:" + cleanString cfg.subscription);
      "dae/sublist".mode = "0600";

      "dae/update-dae-subs.sh".source = pkgs.writeTextFile {
        name = "update-dae-subs.sh";
        text = builtins.readFile ./update-dae-subs.sh;
        executable = true;
      };
    };

    systemd.services.update-dae-subs = {
      description = "Update DAE Subscription Service";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
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
