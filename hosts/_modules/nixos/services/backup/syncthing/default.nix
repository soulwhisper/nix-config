{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.backup;
in
{
  options.modules.services.backup.syncthing = {
    enable = lib.mkEnableOption "syncthing";
  };

  # backup devices files to local

  config = lib.mkIf cfg.syncthing.enable {
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];

    services.caddy.virtualHosts."sync.noirprime.com".extraConfig = ''
      handle {
	      reverse_proxy localhost:9202
      }
    '';

    services.syncthing = {
      dataDir = "${cfg.dataDir}/devices";
      openDefaultPorts = true;
      overrideFolders = true;
      overrideDevices = false;  # allow add devices by gui
      guiAddress = "127.0.0.1:9202";
      settings = {
        options = {
          globalAnnounceEnabled = false; # only sync locally or over vpn
        };
        devices = {
          "ipad" = {
            id = "set-your-device-id-here";
          };
        };
      };
    };
    # systemd.services.syncthing.after = [ "home-manager-soulwhisper.service" ];
    # systemd.services.syncthing-init.after = [ "home-manager-soulwhisper.service" ];
  };
}
