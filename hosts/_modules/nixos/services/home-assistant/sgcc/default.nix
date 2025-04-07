{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.home-assistant;
  configFile = builtins.toFile "options.json" (builtins.readFile ./options.json);
in {
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/sgcc 0755 appuser appuser - -"
      "C ${cfg.dataDir}/sgcc/options.json 0600 appuser appuser - ${configFile}"
    ];

    # service has to be root, or specific user has homeDir;
    # update configs in "${cfg.dataDir}/sgcc/options.json" after init;

    systemd.services.hass-sgcc = {
      description = "Home-assistant SGCC fetcher";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "hass-sgcc-prestart" ''
          test -f "/tmp/chromedriver" || cp ${pkgs.chromedriver}/bin/chromedriver /tmp/chromedriver
        '';
        ExecStart = pkgs.writeShellScript "hass-sgcc-start" ''
          cd ${cfg.dataDir}/sgcc
          ${pkgs.hass-sgcc}/bin/sgcc_fetcher
        '';
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
