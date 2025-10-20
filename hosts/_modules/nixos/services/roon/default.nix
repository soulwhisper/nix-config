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

  config =
    lib.mkIf cfg.server.enable {
      services.roon-server.enable = true;
      services.roon-server.openFirewall = true;
    }
    // lib.optionalAttrs (cfg.bridge.enable) {
      services.roon-bridge.enable = true;
      services.roon-bridge.openFirewall = true;
    };
}
