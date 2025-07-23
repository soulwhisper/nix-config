{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.home-assistant;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [5580];
    networking.firewall.allowedUDPPorts = [5353];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 60000;
        to = 65000;
      }
    ]; # shared high ports for avahi

    networking.enableIPv6 = true;

    services.home-assistant.extraComponents = [
      "matter"
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/hass/matter 0755 appuser appuser - -"
    ];

    systemd.services.matter-server = {
      description = "Matter Server";
      before = ["home-assistant.service"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      environment.HOME = "/var/lib/hass/matter";
      serviceConfig = {
        ExecStart = "${pkgs.python-matter-server}/bin/matter-server --port 5580 --vendorid 4939 --storage-path /var/lib/hass/matter --log-level info";
        BindPaths = "/var/lib/hass/matter:/data";
        ReadOnlyPaths = "/nix/store /run/dbus";
        User = "appuser";
        Group = "appuser";
      };
    };
  };
}
