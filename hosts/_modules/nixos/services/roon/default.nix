{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.roon;
in {
  options.modules.services.roon = {
    server.enable = lib.mkEnableOption "roon-server";
    bridge.enable = lib.mkEnableOption "roon-bridge";
  };

  # roon-server use TCP 9100-9200,9330-9339,30000-30010; UDP 9003;
  # roon-bridge use TCP 9100-9200; UDP 9003;

  config = {
    services.roon-server = lib.mkIf cfg.server.enable {
      enable = true;
      openFirewall = true;
    };
    
    services.roon-bridge = lib.mkIf cfg.bridge.enable {
      enable = true;
      openFirewall = true;
    };
  };
}
