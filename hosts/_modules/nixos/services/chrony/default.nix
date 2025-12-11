{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.chrony;
in {
  options.modules.services.chrony = {
    enable = lib.mkEnableOption "chrony";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [123];

    services.chrony = {
      enable = true;
      package = pkgs.chrony;
      enableNTS = true;
      servers = [
        "time.cloudflare.com"
      ];
      extraConfig = ''
        allow all
        bindaddress 0.0.0.0
      '';
    };
  };
}
