{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.gatus;
in
{
  options.modules.services.gatus = {
    enable = lib.mkEnableOption "gatus";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 9801 ];

    services.gatus = {
      enable = true;
      package = pkgs.unstable.gatus;
      settings = {
        web.port = 9801;
        endpoints = [
          {
            name = "website";
            url = "https://twin.sh/health";
            interval = "5m";
            conditions = [
              "[STATUS] == 200"
              "[BODY].status == UP"
              "[RESPONSE_TIME] < 300"
            ];
          }
        ];
      };
    };
  };
}