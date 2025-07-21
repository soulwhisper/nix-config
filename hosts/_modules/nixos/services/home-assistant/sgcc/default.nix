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
      "d /var/lib/hass/sgcc 0755 appuser appuser - -"
      "C /var/lib/hass/sgcc/options.json 0600 appuser appuser - ${configFile}"
    ];

    # service has to be root, or specific user has homeDir;
    # update configs in "/var/lib/hass/sgcc/options.json" after init;

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
          test -f "/tmp/geckodriver" || cp ${pkgs.geckodriver}/bin/geckodriver /tmp/geckodriver
        '';
        ExecStart = pkgs.writeShellScript "hass-sgcc-start" ''
          cd /var/lib/hass/sgcc
          ${pkgs.hass-sgcc}/bin/sgcc_fetcher
        '';
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
