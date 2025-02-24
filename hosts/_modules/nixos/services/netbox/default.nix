{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.netbox;
  reverseProxyCaddy = config.modules.services.caddy;

  salt = builtins.substring 0 50 (builtins.hashString "sha256" config.networking.hostName);
  saltFile = pkgs.writeTextFile {
    name = "netbox_salt";
    text = salt;
  };
in {
  options.modules.services.netbox = {
    enable = lib.mkEnableOption "netbox";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/opt/apps/netbox";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9203];

    services.caddy.virtualHosts."box.noirprime.com".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9203
      }
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 appuser appuser - -"
    ];

    users.users.netbox.createHome = lib.mkForce false;

    services.netbox = {
      enable = true;
      dataDir = "${cfg.dataDir}";
      port = 9203;
      secretKeyFile = saltFile;
    };
  };
}
