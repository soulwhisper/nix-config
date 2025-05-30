{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.backup.syncthing;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.backup.syncthing = {
    enable = lib.mkEnableOption "syncthing";
  };

  # backup devices files to local
  # user = root, files in zfs pool

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [22000];
    networking.firewall.allowedUDPPorts = [22000 21027];

    services.caddy.virtualHosts."sync.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9203
      }
    '';

    services.syncthing = {
      dataDir = "/var/lib/syncthing";
      user = "root";
      openDefaultPorts = true;
      overrideFolders = true;
      overrideDevices = false; # allow add devices by gui
      guiAddress = "127.0.0.1:9203";
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
