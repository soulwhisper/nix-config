{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.backup.syncthing;
  reverseProxyCaddy = config.modules.services.caddy;
in
{
  options.modules.services.backup.syncthing = {
    enable = lib.mkEnableOption "syncthing";
    dataDir = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
  };

  # backup devices files to local
  # user = root, files in zfs pool

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];

    services.caddy.virtualHosts."sync.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
	      reverse_proxy localhost:9202
      }
    '';

    services.syncthing = {
      dataDir = "${cfg.dataDir}";
      user = "root";
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
