# mater.nix

{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.home-assistant;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [5580];

    networking.enableIPv6 = true;

    services.home-assistant.extraComponents = lib.mkMerge [
      "matter"
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/matter 0755 appuser appuser - -"
    ];

    systemd.services.matter-server = {
      after = [ "network-online.target" ];
      before = [ "home-assistant.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      description = "Matter Server";
      environment.HOME = "${cfg.dataDir}/matter";
      serviceConfig = {
        ExecStart = "${pkgs.python-matter-server}/bin/matter-server --port 5580 --vendorid 4939 --storage-path ${cfg.dataDir}/matter --log-level info";
        TemporaryFileSystem = "/";
        ReadOnlyPaths = "/nix/store /run/dbus";
        BindPaths = "${cfg.dataDir}/matter:/data";
        User = appuser;
        Group = appuser;
    };
  };
}